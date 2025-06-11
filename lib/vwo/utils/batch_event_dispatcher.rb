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

require_relative './network_util'
require_relative '../enums/http_method_enum'
require_relative '../enums/url_enum'
require_relative '../enums/log_level_enum'
require_relative '../services/logger_service'
require_relative '../packages/network_layer/manager/network_manager'
require_relative '../packages/network_layer/models/request_model'

class BatchEventDispatcher

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

      begin
        response = network_instance.post(request)
        handle_batch_response(UrlEnum::BATCH_EVENTS, payload, properties, response, response.get_data, callback)
      rescue StandardError => err
        LoggerService.log(LogLevelEnum::ERROR, "NETWORK_CALL_FAILED", {
              method: "#{HttpMethodEnum::POST} #{UrlEnum::BATCH_EVENTS}",
              err: err.is_a?(Hash) ? err.to_json : err
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
      events_per_request = payload[:ev].length
      account_id = query_params[:a]

      error = res.get_error
      if error
        LoggerService.log(LogLevelEnum::INFO, "IMPRESSION_BATCH_FAILED")
        LoggerService.log(LogLevelEnum::ERROR, "NETWORK_CALL_FAILED", {
          method: "#{HttpMethodEnum::POST} #{UrlEnum::BATCH_EVENTS}",
          err: error
        })
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
          })
          callback.call(error, payload.to_json) if callback.respond_to?(:call)
          return {status: "error", events: payload}
        else
          LoggerService.log(LogLevelEnum::INFO, "IMPRESSION_BATCH_FAILED")
          LoggerService.log(LogLevelEnum::ERROR, "NETWORK_CALL_FAILED", {
              method: "#{HttpMethodEnum::POST} #{UrlEnum::BATCH_EVENTS}",
              err: error
          })
          callback.call(error, payload.to_json) if callback.respond_to?(:call)
          return {status: "error", events: payload}
        end
      end
    end
  end
end
