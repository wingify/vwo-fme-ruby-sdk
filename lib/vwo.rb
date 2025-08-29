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
require_relative 'vwo/vwo_builder'
require_relative 'vwo/vwo_client'
require_relative 'vwo/utils/event_util'
require_relative 'vwo/services/settings_service'

class VWO
  @@vwo_builder = nil
  @@instance = nil

  def initialize(options)
    self.class.set_instance(options)
  end

  def self.set_instance(options)
    options_vwo_builder = options[:vwo_builder]
    @@vwo_builder = options_vwo_builder || VWOBuilder.new(options)

    @@instance = @@vwo_builder
                   .set_logger
                   .set_settings_service
                   .set_storage
                   .set_network_manager
                   .set_segmentation
                   .init_polling
                   .init_usage_stats
                   .init_batch

    if options[:settings]
      return @@vwo_builder.build(options[:settings])
    end

    settings = @@vwo_builder.get_settings
    @@instance = @@vwo_builder.build(settings)
    @@instance
  end

  def self.instance
    @@instance
  end

  def self.init(options)

    begin
      unless options.is_a?(Hash)
        puts "[ERROR]: VWO-SDK: Please provide the options as a hash"
      end

      unless options[:sdk_key]&.is_a?(String) && !options[:sdk_key].empty?
        puts "[ERROR]: VWO-SDK: Please provide the sdkKey in the options and should be a of type string"
      end

      unless options[:account_id] && (options[:account_id].is_a?(Integer) || (options[:account_id].is_a?(String) && !options[:account_id].empty?))
        puts "[ERROR]: VWO-SDK: Please provide VWO account ID in the options and should be a of type string|number"
      end

      # store the current time in milliseconds
      sdk_init_start_time = (Time.now.to_f * 1000).to_i
      # initialize the vwo instance
      new(options)
      # store the time after initializing the vwo instance in milliseconds
      sdk_init_end_time = (Time.now.to_f * 1000).to_i
      # calculate the time taken for initializing the vwo instance
      time_taken_for_init = sdk_init_end_time - sdk_init_start_time
      # get sdkMetaInfo from settings file to check if the sdk was initialized earlier
      sdk_meta_info = nil
      was_initialized_earlier = false
      
      begin
        if @@instance && @@instance.original_settings && @@instance.original_settings.is_a?(Hash)
          sdk_meta_info = @@instance.original_settings["sdkMetaInfo"]
          was_initialized_earlier = sdk_meta_info && sdk_meta_info.is_a?(Hash) ? sdk_meta_info["wasInitializedEarlier"] : false
        end
      rescue StandardError => e
        was_initialized_earlier = false
      end
      if !was_initialized_earlier && SettingsService.instance.is_settings_valid
        # send the sdk init info to vwo server
        send_sdk_init_event(SettingsService.instance.settings_fetch_time, time_taken_for_init.to_s)
      end

      # send the usage stats event to vwo server
      # get usage stats account id from settings
      usage_stats_account_id = @@instance.original_settings["usageStatsAccountId"]
      if usage_stats_account_id
        send_sdk_usage_stats_event(usage_stats_account_id)
      end

      @@instance
    rescue StandardError => e
      puts "[ERROR]: VWO-SDK: Got error while initializing VWO: #{e.message}"
    end
  end
end