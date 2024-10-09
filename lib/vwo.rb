# Copyright 2024 Wingify Software Pvt. Ltd.
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

require_relative 'vwo/utils/logger_helper'
require_relative 'vwo/vwo_client'
require_relative 'vwo/vwo_builder'
require_relative 'vwo/constants'
require_relative 'vwo/utils/request'

# The main VWO module
module VWO
  # Class-level variable to hold the VWO client instance
  @@instance = nil

  # Initialize the VWO SDK with the given options
  def self.init(options = {})
    raise 'options is required to initialize VWO' unless options.is_a?(Hash)
    raise 'sdk_key is required to initialize VWO' if options[:sdk_key].nil? || options[:sdk_key].empty?
    raise 'account_id is required to initialize VWO' if options[:account_id].nil? || options[:account_id].empty?
    raise 'gateway_service_url is required to initialize VWO' if options[:gateway_service_url].nil? || options[:gateway_service_url].empty?

    vwo_init_options = {
      sdk_key: options[:sdk_key],
      account_id: options[:account_id],
      gateway_service_url: options[:gateway_service_url]
    }

    set_instance(vwo_init_options)
  rescue StandardError => e
    LoggerHelper.logger.error("Error initializing VWO: #{e.message}")
    @@instance = VWOClient.new(nil)
  end

  # Set the VWO instance using VWOBuilder and VWOClient
  def self.set_instance(options)
    vwo_builder = VWOBuilder.new(options)
    vwo_builder.init_client
    @@instance = VWOClient.new(options)
  end

  # Get the singleton instance of VWO
  def self.instance
    @@instance
  end
end
