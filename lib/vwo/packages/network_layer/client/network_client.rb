# Copyright 2025 Wingify Software Pvt. Ltd.
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

class NetworkClient
  HTTPS_SCHEME = 'https'

  def initialize(options = {})
    # options for threading
    @should_use_threading = options.key?(:enabled) ? options[:enabled] : Constants::SHOULD_USE_THREADING
    @thread_pool = Concurrent::FixedThreadPool.new(options.key?(:max_pool_size) ? options[:max_pool_size] : Constants::MAX_POOL_SIZE)
  end

  def get_thread_pool
    @thread_pool
  end

  def get(request_model)
    # Build the URL and headers
    url = request_model.get_url + request_model.get_path
    uri = URI(url)
    
    # Create the HTTP GET request
    request = Net::HTTP::Get.new(uri)
    # Add headers to the request
    request_model.get_headers.each { |k, v| request[k] = v }
  
    # Send the GET request and get the response
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end
  
    # Process the response
    response_model = ResponseModel.new
    response_model.set_status_code(response.code.to_i)  # Convert status code to integer
    
    begin
      # Parse the response body as JSON
      parsed_data = JSON.parse(response.body)
      response_model.set_data(parsed_data)
    rescue StandardError => e
      # Handle any JSON parsing errors
      response_model.set_error(e.message)
    end
  
    # Return the response model
    response_model
  end

  def post(request_model)
    def execute_post(request_model)
      url = request_model.get_url + request_model.get_path
      uri = URI(url)
      headers = request_model.get_headers  # Directly use the hash from the request model
      body = JSON.dump(request_model.get_body)
  
      request = Net::HTTP::Post.new(uri, headers)  # Pass the hash of headers directly
      request.body = body
  
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') { |http| http.request(request) }
  
      response_model = ResponseModel.new
      response_model.set_status_code(response.code.to_i)

      # Check if the response body is empty or invalid before parsing
      if response.is_a?(Net::HTTPSuccess) && !response.body.strip.empty?
        begin
          parsed_data = JSON.parse(response.body)
          response_model.set_data(parsed_data)
        rescue JSON::ParserError => e
          # Handle invalid JSON response
          response_model.set_error("Invalid JSON response: #{e.message}")
        end
      else
      end
    rescue StandardError => e
      LoggerService.log(LogLevelEnum::ERROR, "POST request failed: #{e.message}", nil)
    end

    # Check if threading is enabled in options
    if @should_use_threading
      @thread_pool.post { execute_post(request_model) }
    else
      execute_post(request_model)
    end
  end
  
end
