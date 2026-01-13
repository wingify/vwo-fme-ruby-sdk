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

require 'set'
require_relative './network_util'
require_relative '../enums/http_method_enum'
require_relative '../enums/url_enum'
require_relative '../enums/log_level_enum'
require_relative '../enums/event_enum'
require_relative '../services/logger_service'
require_relative '../packages/network_layer/manager/network_manager'
require_relative '../packages/network_layer/models/request_model'
require_relative '../packages/network_layer/models/response_model'
require_relative '../utils/function_util'

class BatchEventDispatcherUtil

  class << self

    # Dispatches a batch of events to the VWO server
    # @param properties [Hash] The event properties to send
    # @param callback [Proc] Optional callback function to execute after the request (defaults to empty proc)
    # @param query_params [Hash] Query parameters to include in the request
    def dispatch(properties, callback = -> {}, query_params)
      # Send the prepared payload via POST API request
      send_batch_post_api_request(query_params, properties, callback)
    end

    # Sends a POST API request with given properties and payload
    def send_batch_post_api_request(properties, payload, callback)
      network_instance = NetworkManager.instance
      headers = {}
      headers['Authorization'] = "#{SettingsService.instance.sdk_key}"

      request = RequestModel.new(
        UrlUtil.get_base_url,
        HttpMethodEnum::POST,
        UrlEnum::BATCH_EVENTS,
        properties,
        payload,
        headers,
        SettingsService.instance.protocol,
        SettingsService.instance.port
      )
      
      event_counts = extract_event_counts(payload)
      extra_data = "#{Constants::BATCH_EVENTS} having"
      if event_counts[:variation_shown_count] > 0
        extra_data += "getFlag events: #{event_counts[:variation_shown_count]}, "
      end
      if event_counts[:custom_event_count] > 0
        extra_data += "conversion events: #{event_counts[:custom_event_count]}, "
      end
      if event_counts[:set_attribute_count] > 0
        extra_data += "setAttribute events: #{event_counts[:set_attribute_count]}, "
      end

      begin
        response = network_instance.post(request)
        # Only send debug event if response is valid and has retry attempts
        if response.is_a?(ResponseModel) && response.get_total_attempts && response.get_total_attempts > 0
          debug_event_props = NetworkUtil.create_network_and_retry_debug_event(response, nil, Constants::BATCH_EVENTS, extra_data)
          # send debug event
          DebuggerServiceUtil.send_debugger_event(debug_event_props) if debug_event_props
        end
        handle_batch_response(UrlEnum::BATCH_EVENTS, payload, properties, response, response.get_data, callback)
      rescue StandardError => err
        # TODO: remove this log after testing
        LoggerService.log(LogLevelEnum::ERROR, "NETWORK_CALL_FAILED", {
              method: extra_data,
              err: get_formatted_error_message(err)
          })
      end
    end

    # Handles the response from a batch event API call
    # @param end_point [String] The API endpoint that was called
    # @param payload [Hash] The payload that was sent in the request
    # @param query_params [Hash] The query parameters used in the request
    # @param res [ResponseModel] The response object from the API call
    # @param raw_data [String] The raw response data from the API
    # @param callback [Proc] Optional callback to be executed after handling the response
    def handle_batch_response(end_point, payload, query_params, res, raw_data, callback)
      # TODO: update this method with debug event logs
      events_per_request = payload[:ev].length
      account_id = query_params[:a]

      error = res.get_error
      if error
        LoggerService.log(LogLevelEnum::INFO, "IMPRESSION_BATCH_FAILED")
        LoggerService.log(LogLevelEnum::ERROR, "NETWORK_CALL_FAILED", {
          method: "#{HttpMethodEnum::POST} #{UrlEnum::BATCH_EVENTS}",
          err: error
        }, false)
        callback.call(error, payload.to_json) if callback.respond_to?(:call)
        return {status: "error", events: payload}
      else
        case res.get_status_code
        when 200
          LoggerService.log(LogLevelEnum::INFO, "IMPRESSION_BATCH_SUCCESS", {
            accountId: account_id,
            endPoint: end_point,
          })
          callback.call(nil, payload.to_json) if callback.respond_to?(:call)
          return {status: "success", events: payload}
        when 413
          LoggerService.log(LogLevelEnum::DEBUG, "CONFIG_BATCH_EVENT_LIMIT_EXCEEDED", {
              accountId: account_id,
              endPoint: end_point,
              eventsPerRequest: events_per_request
          })
          LoggerService.log(LogLevelEnum::ERROR, "NETWORK_CALL_FAILED", {
              method: "#{HttpMethodEnum::POST} #{UrlEnum::BATCH_EVENTS}",
              err: error
          }, false)
          callback.call(error, payload.to_json) if callback.respond_to?(:call)
          return {status: "error", events: payload}
        else
          LoggerService.log(LogLevelEnum::INFO, "IMPRESSION_BATCH_FAILED")
          LoggerService.log(LogLevelEnum::ERROR, "NETWORK_CALL_FAILED", {
              method: "#{HttpMethodEnum::POST} #{UrlEnum::BATCH_EVENTS}",
              err: error
          }, false)
          callback.call(error, payload.to_json) if callback.respond_to?(:call)
          return {status: "error", events: payload}
        end
      end
    end

    # Extracts event counts from a batch payload
    # @param payload [Hash] The payload containing events
    # @return [Hash] Hash with variationShownCount, setAttributeCount, and customEventCount
    def extract_event_counts(payload)
      counts = {
        variation_shown_count: 0,
        set_attribute_count: 0,
        custom_event_count: 0
      }

      # Get all standard event names from EventEnum
      standard_event_names = EventEnum.constants.map { |const| EventEnum.const_get(const) }.to_set
      events = payload&.dig(:ev) || []

      events.each do |entry|
        name = entry&.dig(:d, :event, :name)

        next unless name

        if name == EventEnum::VWO_VARIATION_SHOWN
          counts[:variation_shown_count] += 1
          next
        end

        if name == EventEnum::VWO_SYNC_VISITOR_PROP
          counts[:set_attribute_count] += 1
          next
        end

        unless standard_event_names.include?(name)
          counts[:custom_event_count] += 1
        end
      end

      counts
    end
  end
end
