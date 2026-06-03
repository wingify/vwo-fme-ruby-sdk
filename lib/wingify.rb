# Copyright 2024-2026 Wingify Software Pvt. Ltd.
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
require_relative 'wingify/wingify_builder'
require_relative 'wingify/wingify_client'
require_relative 'wingify/utils/brand_context'
require_relative 'wingify/utils/brand_util'
require_relative 'wingify/utils/event_util'
require_relative 'wingify/services/settings_service'

module Wingify
  @@wingify_builder = nil
  @@instance = nil

  def self.set_instance(options)
    # Set brand flag FIRST — before any service initializes
    BrandContext.set_is_via_vwo(options[:is_via_vwo] || false)

    options_builder = options[:wingify_builder] || options[:vwo_builder]
    @@wingify_builder = options_builder || WingifyBuilder.new(options)

    @@instance = @@wingify_builder
                   .set_logger
                   .set_settings_service
                   .set_storage
                   .set_network_manager
                   .set_segmentation
                   .init_polling
                   .init_usage_stats
                   .init_batch

    if options[:settings]
      return @@wingify_builder.build(options[:settings])
    end

    settings = @@wingify_builder.get_settings
    @@instance = @@wingify_builder.build(settings)
    @@instance
  end

  def self.instance
    @@instance
  end

  def self.init(options)
    begin
      unless options.is_a?(Hash)
        brand = BrandUtil.get_brand_name(options[:is_via_vwo] || false)
        log_prefix = BrandUtil.get_log_prefix(options[:is_via_vwo] || false)
        puts "[ERROR]: #{log_prefix}: Please provide the options as a hash"
        return nil
      end

      brand = BrandUtil.get_brand_name(options[:is_via_vwo] || false)
      log_prefix = BrandUtil.get_log_prefix(options[:is_via_vwo] || false)

      unless options[:sdk_key]&.is_a?(String) && !options[:sdk_key].empty?
        puts "[ERROR]: #{log_prefix}: Please provide the sdkKey in the options and should be a of type string"
      end

      unless options[:account_id] && (options[:account_id].is_a?(Integer) || (options[:account_id].is_a?(String) && !options[:account_id].empty?))
        puts "[ERROR]: #{log_prefix}: Please provide #{brand} account ID in the options and should be a of type string|number"
      end

      sdk_init_start_time = (Time.now.to_f * 1000).to_i
      new_instance = set_instance(options)
      sdk_init_end_time = (Time.now.to_f * 1000).to_i
      time_taken_for_init = sdk_init_end_time - sdk_init_start_time

      was_initialized_earlier = false
      begin
        if new_instance && new_instance.original_settings && new_instance.original_settings.is_a?(Hash)
          sdk_meta_info = new_instance.original_settings["sdkMetaInfo"]
          was_initialized_earlier = sdk_meta_info && sdk_meta_info.is_a?(Hash) ? sdk_meta_info["wasInitializedEarlier"] : false
        end
      rescue StandardError => e
        was_initialized_earlier = false
      end
      
      if !was_initialized_earlier && SettingsService.instance.is_settings_valid
        send_sdk_init_event(SettingsService.instance.settings_fetch_time, time_taken_for_init.to_s)
      end

      usage_stats_account_id = new_instance&.original_settings&.dig("usageStatsAccountId")
      if usage_stats_account_id
        send_sdk_usage_stats_event(usage_stats_account_id)
      end

      new_instance
    rescue StandardError => e
      brand = BrandUtil.get_brand_name(options[:is_via_vwo] || false) rescue 'SDK'
      log_prefix = BrandUtil.get_log_prefix(options[:is_via_vwo] || false) rescue 'SDK'
      puts "[ERROR]: #{log_prefix}: Got error while initializing #{brand}: #{e.message}"
    end
  end

  def self.get_uuid(user_id, account_id)
    if !user_id.is_a?(String) || user_id.empty? || !account_id.is_a?(String) || account_id.empty?
      puts "User ID and account ID must be non-empty strings"
      return nil
    end
    UUIDUtil.get_uuid(user_id, account_id)
  end
end
