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

class VWOOptionsModel
  attr_accessor :account_id, :sdk_key, :is_development_mode, :storage, :gateway_service,
                :poll_interval, :logger, :segmentation, :integrations, :network,
                :should_wait_for_tracking_calls, :settings, :vwo_builder, :is_usage_stats_disabled, :_vwo_meta,
                :retry_config

  def initialize(options = {})
    @account_id = options[:account_id]
    @sdk_key = options[:sdk_key]
    @is_development_mode = options[:is_development_mode]
    @storage = options[:storage]
    @gateway_service = options[:gateway_service]
    @poll_interval = options[:poll_interval]
    @logger = options[:logger]
    @segmentation = options[:segmentation]
    @integrations = options[:integrations]
    @network = options[:network]
    @should_wait_for_tracking_calls = options[:should_wait_for_tracking_calls]
    @settings = options[:settings]
    @vwo_builder = options[:vwo_builder]
    @is_usage_stats_disabled = options[:is_usage_stats_disabled]
    @_vwo_meta = options[:_vwo_meta]
    @retry_config = options[:retry_config]
  end

  # Creates a model instance from a hash (dictionary)
  def model_from_dictionary(options)
    @account_id = options[:account_id]
    @sdk_key = options[:sdk_key]
    @vwo_builder = options[:vwo_builder]

    @should_wait_for_tracking_calls = options[:should_wait_for_tracking_calls] if options.key?(:should_wait_for_tracking_calls)
    @is_development_mode = options[:is_development_mode] if options.key?(:is_development_mode)
    @storage = options[:storage] if options.key?(:storage)
    @gateway_service = options[:gateway_service] if options.key?(:gateway_service)
    @poll_interval = options[:poll_interval] if options.key?(:poll_interval)
    @logger = options[:logger] if options.key?(:logger)
    @segmentation = options[:segmentation] if options.key?(:segmentation)
    @integrations = options[:integrations] if options.key?(:integrations)
    @network = options[:network] if options.key?(:network)
    @settings = options[:settings] if options.key?(:settings)
    @retry_config = options[:retry_config] if options.key?(:retry_config)

    self
  end

  def get_account_id
    @account_id
  end

  def get_sdk_key
    @sdk_key
  end

  def get_is_development_mode
    @is_development_mode
  end

  def get_storage
    @storage
  end

  def get_gateway_service
    @gateway_service
  end

  def get_poll_interval
    @poll_interval
  end

  def get_logger
    @logger
  end

  def get_segmentation
    @segmentation
  end

  def get_integrations
    @integrations
  end

  def get_network
    @network
  end

  def get_should_wait_for_tracking_calls
    @should_wait_for_tracking_calls
  end

  def get_settings
    @settings
  end

  def get_vwo_builder
    @vwo_builder
  end

  def get_is_usage_stats_disabled
    @is_usage_stats_disabled
  end

  def get_vwo_meta
    @_vwo_meta
  end

  def get_retry_config
    @retry_config
  end
  
end
