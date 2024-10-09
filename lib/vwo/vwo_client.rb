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

require 'json'
require_relative 'utils/logger_helper'
require_relative 'constants'
require_relative 'utils/request'
require_relative 'utils/feature_flag_response'

module VWO
  # VWOClient class provides methods to interact with the VWO feature flag system,
  # including retrieving feature flags, tracking events, and setting attributes.
  class VWOClient
    # Makes the `options` instance variable private and only accessible within the class.
    private attr_reader :options

    # Initializes a new instance of the VWOClient.
    #
    # @param [Hash] options Configuration options like account_id and sdk_key.
    def initialize(options)
      @options = options
    end

    # Fetches a feature flag for a given feature_key and context.
    #
    # @param [String] feature_key The unique identifier for the feature flag.
    # @param [Hash] context The context data, which must include a `:id` for user identification.
    #
    # @return [FeatureFlagResponse] Returns a FeatureFlagResponse with the status of the feature flag and any associated variables.
    #         Returns `isEnabled: false` and empty variables if any error occurs.
    #
    # @raise [StandardError] Raises an error if `feature_key`, `context`, or `userId` are missing or invalid.
    def get_flag(feature_key, context)
      # Raise an error if the SDK is not initialized with options.
      raise 'VWO is not initialized' if @options.nil?

      # Validate that feature_key and context are present, and userId is in context.
      raise 'feature_key is required to get the feature flag' if feature_key.nil? || feature_key.empty?
      raise 'context is required to get the feature flag' if context.nil?
      raise 'userId is required for flag evaluation, please provide id in context' if context[:id].nil? || context[:id].empty?

      # Add the feature key to the context.
      context['featureKey'] = feature_key

      # Construct the API endpoint for getting the feature flag.
      endpoint = "#{Constants::ENDPOINT_GET_FLAG}?accountId=#{@options[:account_id]}&sdkKey=#{@options[:sdk_key]}"

      # Send a POST request to retrieve the feature flag.
      response = Utils::Request.send_post_request(endpoint, context)

      # If a response is received, parse it and return a FeatureFlagResponse.
      if response
        parsed_response = JSON.parse(response)
        return FeatureFlagResponse.new(parsed_response['isEnabled'], parsed_response['variables'])
      else
        # Return a default disabled response if no response was received.
        return FeatureFlagResponse.new(false, [])
      end
    rescue StandardError => e
      # Log the error and return a default FeatureFlagResponse with `isEnabled: false`.
      LoggerHelper.logger.error("Error in get_flag: #{e.message}")
      return FeatureFlagResponse.new(false, [])
    end

    # Tracks an event for a given event_name and context.
    #
    # @param [String] event_name The name of the event to track.
    # @param [Hash] context The context data, which must include a `:id` for user identification.
    # @param [Hash] event_properties Optional properties related to the event.
    #
    # @return [String, nil] The response from the server, or nil if an error occurred.
    #
    # @raise [StandardError] Raises an error if `event_name`, `context`, or `userId` are missing or invalid.
    def track_event(event_name, context, event_properties = {})
      # Raise an error if the SDK is not initialized with options.
      raise 'VWO is not initialized' if @options.nil?

      # Validate that event_name and userId in context are present.
      raise 'event_name is required to track the event' if event_name.nil? || event_name.empty?
      raise 'userId is required to track the event, please provide id in context' if context.nil? || context[:id].nil? || context[:id].empty?

      # Add event details to the context.
      context['eventName'] = event_name
      context['eventProperties'] = event_properties

      # Construct the API endpoint for tracking the event.
      endpoint = "#{Constants::ENDPOINT_TRACK_EVENT}?accountId=#{@options[:account_id]}&sdkKey=#{@options[:sdk_key]}"

      # Send a POST request to track the event.
      response = Utils::Request.send_post_request(endpoint, context)

      # Return the server response.
      response
    rescue StandardError => e
      # Log the error if any occurs during event tracking.
      LoggerHelper.logger.error("Error tracking event: #{e.message}")
    end

    # Sets an attribute for a given user context.
    #
    # @param [String] attribute_key The key of the attribute to set.
    # @param [String] attribute_value The value of the attribute to set.
    # @param [Hash] context The context data, which must include a `:id` for user identification.
    #
    # @return [String, nil] The response from the server, or nil if an error occurred.
    #
    # @raise [StandardError] Raises an error if `attribute_key`, `attribute_value`, or `userId` are missing or invalid.
    def set_attribute(attribute_key, attribute_value, context)
      # Raise an error if the SDK is not initialized with options.
      raise 'VWO is not initialized' if @options.nil?

      # Validate that attribute_key, attribute_value, and userId in context are present.
      raise 'attribute_key is required for set_attribute' if attribute_key.nil? || attribute_key.empty?
      raise 'attribute_value is required for set_attribute' if attribute_value.nil?
      raise 'userId is required to set attribute, please provide id in context' if context.nil? || context[:id].nil? || context[:id].empty?

      # Add the attribute details to the context.
      context['attributeKey'] = attribute_key
      context['attributeValue'] = attribute_value

      # Construct the API endpoint for setting the attribute.
      endpoint = "#{Constants::ENDPOINT_SET_ATTRIBUTE}?accountId=#{@options[:account_id]}&sdkKey=#{@options[:sdk_key]}"

      # Send a POST request to set the attribute.
      Utils::Request.send_post_request(endpoint, context)
    rescue StandardError => e
      # Log the error if any occurs during setting the attribute.
      LoggerHelper.logger.error("Error setting attribute: #{e.message}")
    end
  end
end
