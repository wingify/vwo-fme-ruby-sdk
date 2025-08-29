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


require_relative '../constants/constants'
require_relative '../enums/log_level_to_number'

# Manages usage statistics for the SDK.
# Tracks various features and configurations being used by the client.
# Implements Singleton pattern to ensure a single instance.
class UsageStatsUtil
  @instance = nil
  @usage_stats_data = {}

  class << self
    # Provides access to the singleton instance of UsageStatsUtil.
    #
    # @return [UsageStatsUtil] The single instance of UsageStatsUtil
    def instance
      @instance ||= new
    end

    # Sets usage statistics based on provided options.
    # Maps various SDK features and configurations to boolean flags.
    #
    # @param options [Hash] Configuration options for the SDK
    def set_usage_stats(options)
      instance.set_usage_stats(options)
    end

    # Retrieves the current usage statistics.
    #
    # @return [Hash] Record containing boolean flags for various SDK features in use
    def get_usage_stats
      instance.get_usage_stats
    end

    def clear_usage_stats
      instance.clear_usage_stats
    end
  end

  private_class_method :new

  def initialize
    @usage_stats_data = {}
  end

  def set_usage_stats(options)
    storage = options[:storage]
    logger = options[:logger]
    event_batching = options[:batch_event_data]
    integrations = options[:integrations]
    poll_interval = options[:poll_interval]
    vwo_meta = options[:_vwo_meta]
    gateway_service = options[:gateway_service]
    threading = options[:threading]

    data = {}

    data[:a] = SettingsService.instance.account_id
    data[:env] = SettingsService.instance.sdk_key
    data[:ig] = 1 if integrations
    data[:eb] = 1 if event_batching
    data[:gs] = 1 if gateway_service

    # if logger has transport or transports, then it is custom logger
    if logger && (logger.key?(:transport) || logger.key?(:transports))
      data[:cl] = 1
    end

    data[:ss] = 1 if storage

    if logger && logger.key?(:level)
      data[:ll] = LogLevelToNumber.to_number(logger[:level]) || -1
    end

    data[:pi] = poll_interval if poll_interval

    if vwo_meta && vwo_meta.key?(:ea)
      data[:_ea] = 1
    end

    # check if threading is not passed or is if passed then enabled should be true
    if !threading || (threading && threading[:enabled] == true)
      data[:th] = 1
      # check if max_pool_size is passed
      if threading && threading[:max_pool_size]
        data[:th_mps] = threading[:max_pool_size]
      end
    end

    if defined?(RUBY_VERSION)
      data[:lv] = RUBY_VERSION
    end

    @usage_stats_data = data
  end

  def get_usage_stats
    @usage_stats_data
  end

  def clear_usage_stats
    @usage_stats_data = {}
  end
end

