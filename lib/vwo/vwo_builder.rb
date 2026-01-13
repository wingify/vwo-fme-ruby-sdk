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

# require 'json'
# require 'uri'
require_relative './enums/log_level_enum'
require_relative 'vwo_client'
require_relative './services/settings_service'
require_relative './packages/storage/storage'
require_relative './packages/network_layer/manager/network_manager'
require_relative './packages/segmentation_evaluator/core/segmentation_manager'
require_relative './services/logger_service'
require_relative './services/batch_event_queue'
require_relative './utils/function_util'
require_relative './constants/constants'
require_relative './utils/usage_stats_util'
require_relative './enums/api_enum'
require_relative './utils/batch_event_dispatcher_util'

class VWOBuilder
  attr_reader :settings, :storage, :log_manager, :is_settings_fetch_in_progress, :vwo_instance, :is_valid_poll_interval_passed_from_init

  # Initialize the VWOBuilder with the given options
  # @param options [Hash] The options for the VWOBuilder
  def initialize(options)
    @options = options
    @settings = nil
    @storage = nil
    @log_manager = nil
    @is_settings_fetch_in_progress = false
    @is_valid_poll_interval_passed_from_init = false
    @vwo_instance = nil
  end

  # Initializes the batch event processing system
  # Validates batch event settings and configures the BatchEventsQueue
  # Sets up event dispatcher and flushes any existing events
  # @raise [StandardError] If batch event configuration is invalid
  def init_batch
    # if gateway service is configured, then do not initialize batch event queue
    if SettingsService.instance.is_gateway_service_provided
      LoggerService.log(LogLevelEnum::INFO, "GATEWAY_AND_BATCH_EVENTS_CONFIG_MISMATCH")
      return self
    end
    begin
      if @options.key?(:batch_event_data)
        if @options[:batch_event_data].is_a?(Hash)
          # Validate batch event parameters
          events_per_request = @options[:batch_event_data][:events_per_request]
          request_time_interval = @options[:batch_event_data][:request_time_interval]
          
          if (!events_per_request.is_a?(Numeric) || events_per_request <= 0) &&
             (!request_time_interval.is_a?(Numeric) || request_time_interval <= 0)
            LoggerService.log(LogLevelEnum::ERROR, "INVALID_BATCH_EVENTS_CONFIG", { an: ApiEnum::INIT})
          end
          
          BatchEventsQueue.configure(
            @options[:batch_event_data].merge(
              {
                account_id: @options[:account_id],
                dispatcher: method(:dispatcher)
              }
            )
          )
          @batch_event_data = @options[:batch_event_data]
        else
          LoggerService.log(LogLevelEnum::ERROR, "INVALID_BATCH_EVENTS_CONFIG", { an: ApiEnum::INIT})
        end
      end
    rescue StandardError => e
      LoggerService.log(LogLevelEnum::ERROR, "FAILED_TO_INITIALIZE_SERVICE", { service: 'Batch Event Queue', err: e.message, an: ApiEnum::INIT})
    end
  end

  # Set the network manager
  # @return [VWOBuilder] The VWOBuilder instance
  def set_network_manager
    begin
      network_instance = NetworkManager.instance(@options[:threading] || {})
      retry_config = @options[:retry_config]
      client = (@options[:network] && @options[:network][:client]) ? @options[:network][:client] : nil
      network_instance.attach_client(client, retry_config)
      LoggerService.log(LogLevelEnum::DEBUG, "SERVICE_INITIALIZED", {service: "Network Layer"})
      network_instance.get_config.set_development_mode(@options[:is_development_mode]) if @options[:is_development_mode]
      self
    rescue StandardError => e
      LoggerService.log(LogLevelEnum::ERROR, "FAILED_TO_INITIALIZE_SERVICE", { service: 'Network Manager', err: e.message, an: ApiEnum::INIT})
      self
    end
  end

  # Set the segmentation manager
  # @return [VWOBuilder] The VWOBuilder instance
  def set_segmentation
    SegmentationManager.instance.attach_evaluator(@options[:segmentation]) if @options[:segmentation]
    LoggerService.log(LogLevelEnum::DEBUG, "SERVICE_INITIALIZED", {service: "Segmentation Evaluator"})
    self
  end

  # Fetch the settings from the server
  # @param force [Boolean] Whether to force the fetch of settings
  # @return [Hash] The settings
  def fetch_settings(force = false)
    return @settings if !force && @settings
    
    @is_settings_fetch_in_progress = true
    settings = SettingsService.new(@options).get_settings(force)
    @is_settings_fetch_in_progress = false
    @settings = settings unless force
    settings
  end

  # Get the settings from the server
  # @param force [Boolean] Whether to force the fetch of settings
  # @return [Hash] The settings
  def get_settings(force = false)
    return @settings if !force && @settings
    
    begin
      fetch_settings(force)
    rescue StandardError => e
      LoggerService.log(LogLevelEnum::ERROR, "ERROR_FETCHING_SETTINGS", { err: e.message, an: ApiEnum::INIT})
      {}
    end
  end

  # Set the storage
  # @return [VWOBuilder] The VWOBuilder instance
  def set_storage
    if @options[:storage]
      @storage = Storage.instance.attach_connector(@options[:storage])
      Storage.instance.is_storage_enabled = true
    else
      @storage = nil
    end
    LoggerService.log(LogLevelEnum::DEBUG, "SERVICE_INITIALIZED", {service: "Storage"})
    self
  end

  # Set the settings service
  # @return [VWOBuilder] The VWOBuilder instance
  def set_settings_service
    @settings_service = SettingsService.new(@options)
    self
  end

  # Set the logger
  # @return [VWOBuilder] The VWOBuilder instance
  def set_logger
    begin
      @log_manager = LoggerService.new(@options[:logger] || {})
      LoggerService.log(LogLevelEnum::DEBUG, "SERVICE_INITIALIZED", {service: "Logger"})
    rescue => e
      puts "Got error while setting logger: #{e.message}"
    end
    self
  end

  # Initialize the polling
  # @return [VWOBuilder] The VWOBuilder instance
  def init_polling
    poll_interval = @options[:poll_interval]
    
    if poll_interval && poll_interval.is_a?(Numeric) && poll_interval >= 1000
      # this is to check if the poll_interval passed in options is valid
      @is_valid_poll_interval_passed_from_init = true
      check_and_poll
    elsif poll_interval
      # only log error if poll_interval is present in options
      LoggerService.log(LogLevelEnum::ERROR, "INVALID_POLLING_CONFIGURATION", {
        key: 'poll_interval',
        correctType: 'number >= 1000',
        an: ApiEnum::INIT
      })
    end
    self
  end

  # Build the VWO instance
  # @param settings [Hash] The settings for the VWO instance
  # @return [VWOClient] The VWO instance
  def build(settings)
    @vwo_instance = VWOClient.new(settings, @options)
    # if poll_interval is not present in options, set it to the pollInterval from settings
    update_poll_interval_and_check_and_poll(settings)
    @vwo_instance
  end

  def update_poll_interval_and_check_and_poll(settings, should_check_and_poll = true)
    # only update the poll_interval if it poll_interval is not valid or not present in options
    if !@is_valid_poll_interval_passed_from_init
      @options[:poll_interval] = settings["pollInterval"] || Constants::POLLING_INTERVAL
      LoggerService.log(LogLevelEnum::DEBUG, "USING_POLL_INTERVAL_FROM_SETTINGS", {
        source: settings["pollInterval"] ? 'settings' : 'default',
        pollInterval: @options[:poll_interval]
      })
    end
    # should_check_and_poll will be true only when we are updating the poll_interval first time from self.build method
    # if we are updating the poll_interval already running polling, we don't need to check and poll again
    if should_check_and_poll && !@is_valid_poll_interval_passed_from_init
      check_and_poll
    end
  end

  # This method is used to check and poll the settings from the server
  # @return [VWOBuilder] The VWOBuilder instance
  def check_and_poll
    @thread_pool = NetworkManager.instance.get_client.get_thread_pool
    @thread_pool.post do
      loop do
        sleep(@options[:poll_interval]/ 1000.0)
        begin
          latest_settings = fetch_settings(true)
          if latest_settings && latest_settings.to_json != @settings.to_json
            @settings = latest_settings
            LoggerService.log(LogLevelEnum::INFO, "POLLING_SET_SETTINGS")
            @vwo_instance.update_settings(latest_settings.clone, false) if @vwo_instance
            update_poll_interval_and_check_and_poll(latest_settings, false)
          elsif latest_settings
            LoggerService.log(LogLevelEnum::INFO, "POLLING_NO_CHANGE_IN_SETTINGS")
          end
        rescue StandardError => e
          LoggerService.log(LogLevelEnum::ERROR, "ERROR_UPDATING_SETTINGS", { err: e.message, an: ApiEnum::INIT})
        end
      end
    end
  end

  def dispatcher(events, callback)
    BatchEventDispatcherUtil.dispatch(
      {
        ev: events
      },
      callback,
      {
        a: @options[:account_id],
        env: @options[:sdk_key]
      }
    )
  end

  # Initialize the usage stats
  # @return [VWOBuilder] The VWOBuilder instance
  def init_usage_stats
    return self if @options[:is_usage_stats_disabled]

    UsageStatsUtil.set_usage_stats(@options)
    self
  end
end