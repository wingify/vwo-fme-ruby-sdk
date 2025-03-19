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

# require 'json'
# require 'uri'
require_relative './enums/log_level_enum'
require_relative 'vwo_client'
require_relative './services/settings_service'
require_relative './packages/storage/storage'
require_relative './packages/network_layer/manager/network_manager'
require_relative './packages/segmentation_evaluator/core/segmentation_manager'
require_relative './services/logger_service'

class VWOBuilder
  attr_reader :settings, :storage, :log_manager, :is_settings_fetch_in_progress, :vwo_instance

  # Initialize the VWOBuilder with the given options
  # @param options [Hash] The options for the VWOBuilder
  def initialize(options)
    @options = options
    @settings = nil
    @storage = nil
    @log_manager = nil
    @is_settings_fetch_in_progress = false
    @vwo_instance = nil
  end

  # Set the network manager
  # @return [VWOBuilder] The VWOBuilder instance
  def set_network_manager
    begin
      network_instance = NetworkManager.instance(@options[:threading] || {})
      network_instance.attach_client(@options[:network][:client]) if @options[:network] && @options[:network][:client]
      LoggerService.log(LogLevelEnum::DEBUG, "SERVICE_INITIALIZED", {service: "Network Layer"})
      network_instance.get_config.set_development_mode(@options[:is_development_mode]) if @options[:is_development_mode]
      self
    rescue StandardError => e
      LoggerService.log(LogLevelEnum::ERROR, "Failed to initialize network manager: #{e.message}", nil)
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
      LoggerService.log(LogLevelEnum::ERROR, "Failed to fetch settings: #{e.message}", nil)
      {}
    end
  end

  # Set the storage
  # @return [VWOBuilder] The VWOBuilder instance
  def set_storage
    @storage = @options[:storage] ? Storage.instance.attach_connector(@options[:storage]) : nil
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
    return self unless @options[:poll_interval]

    unless @options[:poll_interval].is_a?(Numeric)
      LoggerService.log(LogLevelEnum::ERROR, "INIT_OPTIONS_INVALID", {
        key: 'poll_interval',
        correctType: 'number'
      })
      return self
    end

    # Check if the polling interval is greater than or equal to 1000
    unless @options[:poll_interval] >= 1000
      LoggerService.log(LogLevelEnum::ERROR, "INIT_OPTIONS_INVALID", {
        key: 'poll_interval',
        correctType: 'number'
      })
      return self
    end

    check_and_poll
    self
  end

  # Build the VWO instance
  # @param settings [Hash] The settings for the VWO instance
  # @return [VWOClient] The VWO instance
  def build(settings)
    @vwo_instance = VWOClient.new(settings, @options)
    @vwo_instance
  end

  # This method is used to check and poll the settings from the server
  # @return [VWOBuilder] The VWOBuilder instance
  def check_and_poll
    polling_interval = @options[:poll_interval]

    @thread_pool = NetworkManager.instance.get_client.get_thread_pool
    @thread_pool.post do
      loop do
        sleep(polling_interval / 1000.0)
        begin
          latest_settings = fetch_settings(true)
          if latest_settings.to_json != @settings.to_json
            @settings = latest_settings
            LoggerService.log(LogLevelEnum::INFO, "POLLING_SET_SETTINGS")
            @vwo_instance.update_settings(latest_settings.clone, false) if @vwo_instance
          else
            LoggerService.log(LogLevelEnum::INFO, "POLLING_NO_CHANGE_IN_SETTINGS")
          end
        rescue StandardError => e
          LoggerService.log(LogLevelEnum::ERROR, "POLLING_FETCH_SETTINGS_FAILED")
        end
      end
    end
  end
end