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
require_relative '../packages/network_layer/manager/network_manager'
require_relative '../packages/network_layer/models/request_model'
require_relative '../packages/network_layer/models/response_model'
require_relative '../constants/constants'
require_relative '../utils/network_util'
require_relative '../services/logger_service'
require_relative '../enums/log_level_enum'
require_relative '../models/schemas/settings_schema_validation'

class SettingsService
  attr_accessor :sdk_key, :account_id, :expiry, :network_timeout, :hostname, :port, :protocol, :is_gateway_service_provided, :is_settings_valid, :settings_fetch_time

  class << self
    attr_accessor :instance

    def get_instance
      @instance ||= SettingsService.new
    end
  end

  def initialize(options)
    @sdk_key = options[:sdk_key]
    @account_id = options[:account_id]
    @expiry = options.dig(:settings, :expiry) || Constants::SETTINGS_EXPIRY
    @network_timeout = options.dig(:settings, :timeout) || Constants::SETTINGS_TIMEOUT
    @is_settings_valid = false

    if options[:gateway_service] && options[:gateway_service][:url]
      parsed_url = URI.parse(options[:gateway_service][:url].start_with?(Constants::HTTP_PROTOCOL) || options[:gateway_service][:url].start_with?(Constants::HTTPS_PROTOCOL) ? options[:gateway_service][:url] : "#{Constants::HTTPS_PROTOCOL}#{options[:gateway_service][:url]}")
      @hostname = parsed_url.hostname
      @protocol = parsed_url.scheme
      @port = parsed_url.port || options.dig(:gateway_service, :port)
      @is_gateway_service_provided = true
    else
      @hostname = Constants::HOST_NAME
      @protocol = Constants::HTTPS_PROTOCOL
    end

    LoggerService.log(LogLevelEnum::DEBUG, "SERVICE_INITIALIZED", { service: 'Settings Manager' })
    SettingsService.instance = self
  end

  # Fetch settings and cache them in storage.
  # @return [SettingsModel] The fetched settings
  def fetch_settings_and_cache_in_storage
    begin
      response = fetch_settings
      response
    rescue => e
      LoggerService.log(LogLevelEnum::ERROR, "SETTINGS_FETCH_ERROR", { err: e.message })
      nil
    end
  end

  # Fetch settings from the server.
  # @param is_via_webhook [Boolean] Whether to fetch settings via webhook
  # @return [SettingsModel] The fetched settings
  def fetch_settings(is_via_webhook = false)
    if @sdk_key.nil? || @account_id.nil?
      LoggerService.log(LogLevelEnum::ERROR, "sdkKey is required for fetching account settings. Aborting!", nil)
    end

    network_instance = NetworkManager.instance
    options = NetworkUtil.get_settings_path(@sdk_key, @account_id)

    options['api-version'] = Constants::API_VERSION
    options[:source] = 'prod'
    options[:sn] = Constants::SDK_NAME
    options[:sv] = Constants::SDK_VERSION

    # When using gateway service, always fetch from SETTINGS_ENDPOINT since the gateway maintains the latest settings
    if @is_gateway_service_provided
      path = Constants::SETTINGS_ENDPOINT
    else
      path = is_via_webhook ? Constants::WEBHOOK_SETTINGS_ENDPOINT : Constants::SETTINGS_ENDPOINT
    end

    request = RequestModel.new(@hostname, "GET", path, options, nil, nil, @protocol, @port)
    request.set_timeout(@network_timeout)

    # store the current time in milliseconds
    settings_fetch_start_time = (Time.now.to_f * 1000).to_i

    begin
      response = network_instance.get(request)
      # calculate the time taken to fetch the settings
      settings_fetch_end_time = (Time.now.to_f * 1000).to_i
      time_taken = settings_fetch_end_time - settings_fetch_start_time
      @settings_fetch_time = time_taken.to_s 
      response.get_data
    rescue => e
      LoggerService.log(LogLevelEnum::ERROR, "Error fetching settings: #{e.message}", nil)
      raise e
    end
  end

  # Get settings (either from storage or by forcing fetch).
  # @param force_fetch [Boolean] Whether to force fetch the settings
  # @return [SettingsModel] The fetched settings
  def get_settings(force_fetch = false)
    if force_fetch
      fetch_settings_and_cache_in_storage
    else
      settings = fetch_settings_and_cache_in_storage
      is_valid = SettingsSchema.new.is_settings_valid(settings)
      if is_valid
        @is_settings_valid = true
        LoggerService.log(LogLevelEnum::INFO, "SETTINGS_FETCH_SUCCESS")
        settings
      else
        LoggerService.log(LogLevelEnum::ERROR, "SETTINGS_SCHEMA_INVALID")
        {}
      end
    end
  end
end
