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
class NetworkManager
  @instance = nil

  def initialize(options = {})
    @client = NetworkClient.new(options)
    @config = GlobalRequestModel.new(nil, {}, {}, {})
    @should_use_threading = options.key?(:enabled) ? options[:enabled] : Constants::SHOULD_USE_THREADING
  end

  def self.instance(options = {})
    @instance ||= new(options)
  end

  def attach_client(client = nil)
    @client = client || NetworkClient.new(@should_use_threading)
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
    RequestHandler.new.create_request(request, @config)
  end

  def get(request)
    begin
      network_options = create_request(request)
      raise 'No URL found' if network_options.get_url.nil?
  
      response = @client.get(network_options)
      response
    rescue => e
      LoggerService.log(LogLevelEnum::ERROR, "Error getting: #{e.message}", nil)
      raise e
    end
  end
  

  def post(request)
    begin
      network_options = create_request(request)
      raise 'No URL found' if network_options.get_url.nil?
  
      response = @client.post(network_options) # Return the response
      response
    rescue => e
      LoggerService.log(LogLevelEnum::ERROR, "Error posting: #{e.message}", nil)
      return ResponseModel.new.set_error(e.message) # Return error response
    end
  end
end
