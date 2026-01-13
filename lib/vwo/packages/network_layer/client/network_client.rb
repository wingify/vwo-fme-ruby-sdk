# Copyright 2024-2025 Wingify Software Pvt. Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'json'
require 'uri'
require_relative '../models/request_model'
require_relative '../models/response_model'
require_relative '../../../utils/network_util'
require 'net/http'
require 'concurrent-ruby'
require_relative '../../../constants/constants'
require_relative '../../../services/logger_service'
require_relative '../../../enums/log_level_enum'
require_relative '../../../enums/event_enum'
require_relative '../../../utils/function_util'

class NetworkClient
  HTTPS_SCHEME = 'https'

  def initialize(options = {})
    # options for threading
    @should_use_threading = options.key?(:enabled) ? options[:enabled] : Constants::SHOULD_USE_THREADING
    @thread_pool = Concurrent::ThreadPoolExecutor.new(
      # Minimum number of threads to keep alive in the pool
      min_threads: 1,
      # Maximum number of threads allowed in the pool, configurable via options or defaults to MAX_POOL_SIZE constant
      max_threads: options.key?(:max_pool_size) ? options[:max_pool_size] : Constants::MAX_POOL_SIZE,
      # Maximum number of tasks that can be queued when all threads are busy
      max_queue: options.key?(:max_queue_size) ? options[:max_queue_size] : Constants::MAX_QUEUE_SIZE,
      # When queue is full, execute task in the caller's thread rather than rejecting it
      fallback_policy: :caller_runs
    )
  end

  def get_thread_pool
    @thread_pool
  end

  def get_should_use_threading
    @should_use_threading
  end

  def get(request_model)
    execute_with_retry(request_model, :get_request)
  end

  def post(request_model)
    execute_with_retry(request_model, :post_request)
  end

  private

  def execute_with_retry(request_model, request_type)
    url = request_model.get_url + request_model.get_path
    uri = URI(url)
    attempt = 0

    # Get retry config from request model or use defaults
    retry_config = request_model.get_retry_config || Constants::DEFAULT_RETRY_CONFIG.dup
    extra_data = request_model.get_extra_info
    endpoint = request_model.get_path.split('?')[0]
    
    # If retry is disabled, execute without retry logic
    unless retry_config[:should_retry]
      response_model, _should_retry, _last_error_message =
        perform_single_attempt(uri, request_model, request_type, attempt, retry_config)
      return response_model
    end

    # Attempt loop: initial attempt (0) + configured retries
    last_error_message = nil
    last_response_model = nil

    (0..retry_config[:max_retries] - 1).each do |attempt_index|
      attempt = attempt_index

      # Perform a single attempt
      response_model, should_retry, last_error_message =
        perform_single_attempt(uri, request_model, request_type, attempt, retry_config, last_error_message)

      last_response_model = response_model

      # If there is no retry needed, return immediately
      return response_model unless should_retry

      # Calculate delay before next retry (in seconds)
      delay_seconds = calculate_retry_delay(attempt_index, retry_config)

      # Log retry attempt
      LoggerService.log(
        LogLevelEnum::ERROR,
        "ATTEMPTING_RETRY_FOR_FAILED_NETWORK_CALL",
        {
          endPoint: endpoint,
          err: last_error_message,
          delay: delay_seconds,
          attempt: attempt_index + 1,
          maxRetries: retry_config[:max_retries]
        }.merge(extra_data), false
      )

      # Store last error on request for diagnostics
      request_model.set_last_error(last_error_message)

      sleep(delay_seconds)
    end

    # All attempts exhausted
    total_attempts = retry_config[:max_retries]
    final_error_message = last_error_message || 'Unknown error'

    # Log failure after max retries (skip for debugger events)
    unless endpoint.include?(EventEnum::VWO_DEBUGGER_EVENT)
      LoggerService.log(
        LogLevelEnum::ERROR,
        "NETWORK_CALL_FAILURE_AFTER_MAX_RETRIES",
        {
          extraData: endpoint,
          attempts: total_attempts,
          err: final_error_message
        }.merge(extra_data), 
        false
      )
    end

    if last_response_model
      last_response_model.set_total_attempts(total_attempts)
      last_response_model.set_error(final_error_message)
      last_response_model
    else
      response_model = ResponseModel.new
      response_model.set_error(final_error_message)
      response_model.set_total_attempts(total_attempts)
      response_model
    end
  end

  # Performs a single HTTP attempt (GET/POST) and returns:
  # [ResponseModel, should_retry (Boolean), last_error_message (String or nil)]
  def perform_single_attempt(uri, request_model, request_type, attempt, retry_config, prev_error_message = nil)
    begin
      # Low-level HTTP call
      response = if request_type == :get_request
                   perform_get_request(uri, request_model)
                 else
                   perform_post_request(uri, request_model)
                 end

      response_model = build_response_model(response)

      # Success (2xx)
      if response.is_a?(Net::HTTPSuccess)
        # On retries, echo back last error and attempts (for diagnostics)
        if attempt.positive?
          response_model.set_total_attempts(attempt)
          response_model.set_error(request_model.get_last_error)
        end
        return [response_model, false, nil]
      end

      # Client error 400 → do not retry
      if response.code.to_i == 400
        error_message = "#{response.body}, Status Code: #{response.code.to_i}"
        response_model.set_error(error_message)
        response_model.set_total_attempts(attempt)
        return [response_model, false, error_message]
      end

      # Non-2xx/400 status → decide if we should retry based on status code
      should_retry = should_retry(response, attempt, retry_config)
      error_message = "#{response.body}, Status Code: #{response.code.to_i}"
      response_model.set_error(error_message)
      response_model.set_total_attempts(attempt)
      [response_model, should_retry, error_message]
    rescue StandardError => e
      # Network / timeout / other exceptions
      error_message = get_formatted_error_message(e)
      response_model = ResponseModel.new
      response_model.set_error(error_message)
      response_model.set_total_attempts(attempt)

      should_retry = should_retry_on_error(e, attempt, retry_config)
      [response_model, should_retry, error_message]
    end
  end

  def perform_get_request(uri, request_model)
    request = Net::HTTP::Get.new(uri)
    request_model.get_headers.each { |k, v| request[k] = v }

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https', open_timeout: Constants::REQUEST_TIMEOUT, read_timeout: Constants::REQUEST_TIMEOUT) do |http|
      http.request(request)
    end
  end

  def perform_post_request(uri, request_model)
    headers = request_model.get_headers
    body = JSON.dump(request_model.get_body)

    request = Net::HTTP::Post.new(uri, headers)
    request.body = body

    Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https', open_timeout: Constants::REQUEST_TIMEOUT, read_timeout: Constants::REQUEST_TIMEOUT) do |http|
      http.request(request)
    end
  end

  def build_response_model(response)
    response_model = ResponseModel.new
    response_model.set_status_code(response.code.to_i)

    if response.is_a?(Net::HTTPSuccess) && !response.body.strip.empty?
      content_type = response['Content-Type']&.downcase
      if content_type&.include?('application/json')
        begin
          parsed_data = JSON.parse(response.body)
          response_model.set_data(parsed_data)
        rescue JSON::ParserError => e
          response_model.set_error("Invalid JSON response: #{e.message}")
        end
      else
        response_model.set_data(response.body)
      end
    end

    response_model
  end

  def should_retry(response, attempt, retry_config)
    # Retry on server errors (5xx) or network timeouts
    status_code = response.code.to_i
    status_code < 200 || status_code > 300
  end

  def should_retry_on_error(error, attempt, retry_config)
    return false if attempt >= retry_config[:max_retries]

    # Retry on network errors, timeouts, and connection errors
    # Check for specific error types that indicate transient network issues
    retryable = error.is_a?(Net::OpenTimeout) ||
                error.is_a?(Net::ReadTimeout) ||
                error.is_a?(Errno::ECONNREFUSED) ||
                error.is_a?(Errno::ETIMEDOUT) ||
                error.is_a?(Errno::EHOSTUNREACH) ||
                error.is_a?(Errno::ENETUNREACH) ||
                error.is_a?(Errno::ECONNRESET) ||
                error.is_a?(Errno::EPIPE) ||
                error.is_a?(SocketError) ||
                (error.respond_to?(:message) && error.message && 
                 (error.message.downcase.include?('timeout') || 
                  error.message.downcase.include?('connection') ||
                  error.message.downcase.include?('connection refused') ||
                  error.message.downcase.include?('getaddrinfo') ||
                  error.message.downcase.include?('connection reset') ||
                  error.message.downcase.include?('broken pipe')))

    retryable
  end

  def calculate_retry_delay(attempt, retry_config)
    retry_config[:initial_delay] * (retry_config[:backoff_multiplier] ** attempt)
  end

  
end
