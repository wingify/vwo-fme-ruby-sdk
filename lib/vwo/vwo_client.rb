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

require_relative 'services/settings_service'
require_relative 'models/user/context_model'
require_relative 'api/get_flag'
require_relative 'api/set_attribute'
require_relative 'api/track_event'
require_relative 'utils/url_util'
require_relative 'utils/settings_util'
require_relative 'services/logger_service'
require_relative 'enums/log_level_enum'
require_relative 'utils/network_util'
require_relative 'models/schemas/settings_schema_validation'
require_relative 'services/batch_event_queue'

class VWOClient
  attr_accessor :settings, :original_settings
  attr_reader :options

  def initialize(settings, options)
    @options = options
    @settings = settings
    @original_settings = settings.dup
    
    begin
      set_settings_and_add_campaigns_to_rules(settings, self)
      UrlUtil.init(collection_prefix: @settings.get_collection_prefix)
    rescue StandardError => e
      LoggerService.log(LogLevelEnum::ERROR, "Error setting and adding campaigns to rules message: #{e.message}", nil)
    end
    LoggerService.log(LogLevelEnum::INFO, "CLIENT_INITIALIZED")
    self
  end

  # Get the flag for a given feature key and context
  # @param feature_key [String] The key of the feature to get the flag for
  # @param context [Hash] The context of the user
  # @return [GetFlagResponse] The flag for the given feature key and context
  def get_flag(feature_key, context)
    api_name = 'get_flag'
    error_response = GetFlagResponse.new(false, [])
  
    begin
      hooks_service = HooksService.new(@options)
      LoggerService.log(LogLevelEnum::DEBUG, "API_CALLED", {apiName: api_name})

      unless feature_key.is_a?(String) && !feature_key.empty?
        LoggerService.log(LogLevelEnum::ERROR, "API_INVALID_PARAM", {apiName: api_name, key: 'feature_key', type: feature_key.class.name , correctType: 'String'})
        raise TypeError, 'feature_key should be a non-empty string'
      end
      unless SettingsService.instance.is_settings_valid
        LoggerService.log(LogLevelEnum::ERROR, "API_SETTING_INVALID")
        raise TypeError, 'Invalid Settings'
      end
      unless context.is_a?(Hash)
        LoggerService.log(LogLevelEnum::ERROR, "API_CONTEXT_INVALID")
        raise TypeError, 'Invalid context'
      end
      unless context[:id].is_a?(String) && !context[:id].empty?
        LoggerService.log(LogLevelEnum::ERROR, "API_INVALID_PARAM", {apiName: api_name, key: 'context.id', type: context[:id].class.name, correctType: 'String'})
        raise TypeError, 'Invalid context, id should be a non-empty string'
      end
      
      context_model = ContextModel.new.model_from_dictionary(context)
      FlagApi.new.get(feature_key, @settings, context_model, hooks_service)
    rescue StandardError => e
      LoggerService.log(LogLevelEnum::ERROR, "API_THROW_ERROR", {apiName: api_name, err: e.message})
      error_response
    end
  end

  # Track an event with given properties and context
  # @param event_name [String] The name of the event to track
  # @param context [Hash] The context of the user
  # @param event_properties [Hash] The properties of the event
  # @return [Hash] The result of the event tracking
  def track_event(event_name, context, event_properties = {})
    api_name = 'track_event'
    
    begin
      hooks_service = HooksService.new(@options)
      LoggerService.log(LogLevelEnum::DEBUG, "API_CALLED", {apiName: api_name})
      
      unless event_name.is_a?(String) && !event_name.empty?
        LoggerService.log(LogLevelEnum::ERROR, "API_INVALID_PARAM", {apiName: api_name, key: 'event_name', type: event_name.class.name, correctType: 'String'})
        raise TypeError, 'event_name should be a non-empty string'
      end
      unless event_properties.is_a?(Hash)
        LoggerService.log(LogLevelEnum::ERROR, "API_INVALID_PARAM", {apiName: api_name, key: 'event_properties', type: event_properties.class.name, correctType: 'Hash'})
        raise TypeError, 'event_properties should be a hash'
      end
      unless SettingsService.instance.is_settings_valid
        LoggerService.log(LogLevelEnum::ERROR, "API_SETTING_INVALID")
        raise TypeError, 'Invalid Settings'
      end
      unless context[:id].is_a?(String) && !context[:id].empty?
        LoggerService.log(LogLevelEnum::ERROR, "API_INVALID_PARAM", {apiName: api_name, key: 'context.id', type: context[:id].class.name, correctType: 'String'})
        raise TypeError, 'Invalid context, id should be a non-empty string'
      end
      
      context_model = ContextModel.new.model_from_dictionary(context)
      TrackApi.new.track(@settings, event_name, context_model, event_properties, hooks_service)
    rescue StandardError => e
      LoggerService.log(LogLevelEnum::ERROR, "API_THROW_ERROR", {apiName: api_name, err: e.message})
      { event_name: false }
    end
  end

  # Set attributes for a given context
  # @param attributes [Hash] The attributes to set
  # @param context [Hash] The context of the user
  # @return [Hash] The result of the attribute setting
  def set_attribute(attributes, context = nil)
    api_name = 'set_attribute'
    
    begin
      LoggerService.log(LogLevelEnum::DEBUG, "API_CALLED", {apiName: api_name})

      unless attributes.is_a?(Hash) && !attributes.empty?
        LoggerService.log(LogLevelEnum::ERROR, "API_INVALID_PARAM", {apiName: api_name, key: 'attributes', type: attributes.class.name, correctType: 'Hash'})
        raise TypeError, 'Attributes should be a hash with key-value pairs and non-empty'
      end
      unless context.is_a?(Hash)
        LoggerService.log(LogLevelEnum::ERROR, "API_INVALID_PARAM", {apiName: api_name, key: 'context', type: context.class.name, correctType: 'Hash'})
        raise TypeError, 'Invalid context'
      end
      unless context[:id].is_a?(String) && !context[:id].empty?
        LoggerService.log(LogLevelEnum::ERROR, "API_INVALID_PARAM", {apiName: api_name, key: 'context.id', type: context[:id].class.name, correctType: 'String'})
        raise TypeError, 'Invalid context, id should be a non-empty string'
      end
      unless SettingsService.instance.is_settings_valid
        LoggerService.log(LogLevelEnum::ERROR, "API_SETTING_INVALID")
        raise TypeError, 'Invalid Settings'
      end
      
      context_model = ContextModel.new.model_from_dictionary(context)
      SetAttributeApi.new.set_attribute(attributes, context_model)
    rescue StandardError => e
      LoggerService.log(LogLevelEnum::ERROR, "API_THROW_ERROR", {apiName: api_name, err: e.message})
    end
  end

  # Update the settings of the VWO client instance
  # @param settings [Hash] The settings to update with (optional)
  # @param is_via_webhook [Boolean] Whether the update is via webhook (default: true)
  # @return [void]
  def update_settings(settings = nil, is_via_webhook = true)
    api_name = 'update_settings'
    
    begin
      LoggerService.log(LogLevelEnum::DEBUG, "API_CALLED", {apiName: api_name})
      
      # Fetch settings from server or use provided settings if not empty
      settings_to_update = if settings.nil? || settings.empty?
        SettingsService.instance.fetch_settings(is_via_webhook)
      else
        settings
      end

      # Validate settings schema
      unless SettingsSchema.new.is_settings_valid(settings_to_update)
        LoggerService.log(LogLevelEnum::ERROR, "API_SETTING_INVALID")
        raise TypeError, 'Invalid Settings'
      end

      # Set the settings on the client instance
      set_settings_and_add_campaigns_to_rules(settings_to_update, self)
      LoggerService.log(LogLevelEnum::INFO, "SETTINGS_UPDATED", {apiName: api_name, isViaWebhook: is_via_webhook})
    rescue StandardError => e
      LoggerService.log(
        LogLevelEnum::ERROR,
        "SETTINGS_FETCH_FAILED",
        {
          apiName: api_name,
          isViaWebhook: is_via_webhook,
          err: e.message
        }
      )
    end
  end

  # Flushes the batch events queue
  # @return [void]
  def flush_events
    api_name = 'flush_events'
    begin
      LoggerService.log(LogLevelEnum::DEBUG, "API_CALLED", {apiName: api_name})
      if BatchEventsQueue.instance.nil?
        LoggerService.log(LogLevelEnum::ERROR, "Batching is not enabled. Pass batch_event_data in the SDK configuration while invoking init API.", nil)
        raise StandardError, "Batch events queue is not initialized"
      end
      # flush the batch events queue
      @response = BatchEventsQueue.instance.flush(true)
      @response
    rescue StandardError => e
      LoggerService.log(LogLevelEnum::ERROR, "API_THROW_ERROR", {apiName: api_name, err: e.message})
    end
  end
end
