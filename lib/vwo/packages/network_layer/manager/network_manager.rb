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

require_relative '../client/network_client'
require_relative '../handlers/request_handler'
require_relative '../models/global_request_model'
require_relative '../../../services/logger_service'
require_relative '../../../enums/log_level_enum'
require_relative '../../../constants/constants'
require_relative '../../../enums/api_enum'
require_relative '../../../utils/data_type_util'

class NetworkManager
  @instance = nil

  def initialize(options = {})
    @client = NetworkClient.new(options)
    @config = GlobalRequestModel.new(nil, {}, {}, {})
    @should_use_threading = options.key?(:enabled) ? options[:enabled] : Constants::SHOULD_USE_THREADING
    @retry_config = nil
  end

  def self.instance(options = {})
    @instance ||= new(options)
  end

  def attach_client(client = nil, retry_config = nil)
    # Only set retry configuration if it's not already initialized or if a new config is provided
    if !@retry_config || retry_config
      # Define default retry configuration
      default_retry_config = Constants::DEFAULT_RETRY_CONFIG.dup

      # Merge provided retry_config with defaults, giving priority to provided values
      merged_config = default_retry_config.merge(retry_config || {})

      # Validate the merged configuration
      @retry_config = validate_retry_config(merged_config)
    end
  end

  def get_retry_config
    @retry_config ? @retry_config.dup : nil
  end

  def validate_retry_config(retry_config)
    validated_config = retry_config.dup
    is_invalid_config = false

    # Validate should_retry: should be a boolean value
    if !DataTypeUtil.is_boolean(validated_config[:should_retry])
      validated_config[:should_retry] = Constants::DEFAULT_RETRY_CONFIG[:should_retry]
      is_invalid_config = true
    end

    # Validate max_retries: should be a non-negative integer and should not be less than 1
    if !DataTypeUtil.is_number(validated_config[:max_retries]) ||
       !validated_config[:max_retries].is_a?(Integer) ||
       validated_config[:max_retries] < 1
      validated_config[:max_retries] = Constants::DEFAULT_RETRY_CONFIG[:max_retries]
      is_invalid_config = true
    end

    # Validate initial_delay: should be a non-negative integer and should not be less than 1
    if !DataTypeUtil.is_number(validated_config[:initial_delay]) ||
       !validated_config[:initial_delay].is_a?(Integer) ||
       validated_config[:initial_delay] < 1
      validated_config[:initial_delay] = Constants::DEFAULT_RETRY_CONFIG[:initial_delay]
      is_invalid_config = true
    end

    # Validate backoff_multiplier: should be a non-negative integer and should not be less than 2
    if !DataTypeUtil.is_number(validated_config[:backoff_multiplier]) ||
       !validated_config[:backoff_multiplier].is_a?(Integer) ||
       validated_config[:backoff_multiplier] < 2
      validated_config[:backoff_multiplier] = Constants::DEFAULT_RETRY_CONFIG[:backoff_multiplier]
      is_invalid_config = true
    end

    if is_invalid_config
      LoggerService.log(LogLevelEnum::ERROR, "INVALID_RETRY_CONFIG", {
        retryConfig: validated_config.to_json,
        an: ApiEnum::INIT
      })
    end

    is_invalid_config ? Constants::DEFAULT_RETRY_CONFIG.dup : validated_config
  end

  def get_client
    @client
  end

  def set_config(config)
    @config = config
  end

  def get_config
    @config
  end

  def create_request(request)
    network_request = RequestHandler.new.create_request(request, @config)
    # Set retry config from network manager if not already set in request
    if @retry_config && (!network_request.get_retry_config || network_request.get_retry_config.nil?)
      network_request.set_retry_config(@retry_config.dup)
    end
    network_request
  end

  def get(request)
    begin
      network_options = create_request(request)
      raise 'No URL found' if network_options.get_url.nil?
  
      response = @client.get(network_options)
      response
    rescue => e
      return ResponseModel.new.set_error(e.message)
    end
  end
  

  def post(request)
    begin
      network_options = create_request(request)
      raise 'No URL found' if network_options.get_url.nil?
  
      response = @client.post(network_options) # Return the response
      response
    rescue => e
      return ResponseModel.new.set_error(e.message) # Return error response
    end
  end
end
