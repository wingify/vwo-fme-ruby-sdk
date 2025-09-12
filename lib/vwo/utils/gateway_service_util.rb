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

require_relative '../models/settings/settings_model'
require_relative '../packages/network_layer/manager/network_manager'
require_relative '../packages/network_layer/models/request_model'
require_relative '../enums/http_method_enum'
require_relative '../services/settings_service'
require_relative 'url_util'
require_relative '../enums/campaign_type_enum'
require_relative '../services/logger_service'
require_relative '../enums/log_level_enum'

# Retrieves data from a web service using the specified query parameters and endpoint.
# @param query_params [Hash] The parameters to be used in the query string of the request.
# @param endpoint [String] The endpoint URL to which the request is sent.
# @return [Hash, Boolean] The response data or false if an error occurs.
def get_from_gateway_service(query_params, endpoint)
  network_instance = NetworkManager.instance

  unless SettingsService.instance.is_gateway_service_provided
    LoggerService.log(LogLevelEnum::ERROR, "GATEWAY_URL_ERROR")
    return false
  end

  begin
    request = RequestModel.new(
      UrlUtil.get_base_url,
      HttpMethodEnum::GET,
      endpoint,
      query_params,
      nil,
      nil,
      SettingsService.instance.protocol,
      SettingsService.instance.port
    )

    response = network_instance.get(request)
    return response.get_data
  rescue StandardError => e
    LoggerService.log(LogLevelEnum::ERROR, "Error fetching from Gateway Service: #{e.message}", nil)
    return false
  end
end

# Encodes the query parameters to ensure they are URL-safe.
# @param query_params [Hash] The query parameters to be encoded.
# @return [Hash] An object containing the encoded query parameters.
def get_query_params(query_params)
  encoded_params = {}

  query_params.each do |key, value|
    encoded_params[key] = URI.encode_www_form_component(value.to_s)
  end

  encoded_params
end

# Adds isGatewayServiceRequired flag to each feature in the settings based on pre-segmentation.
# @param settings [SettingsModel] The settings file to modify.
def add_is_gateway_service_required_flag(settings)
  pattern = /
    (?!custom_variable\s*:\s*{\s*"name"\s*:\s*")   # Prevent matching inside custom_variable
    \b(country|region|city|os|device|device_type|browser_string|ua|browser_version|os_version)\b
    |
    "custom_variable"\s*:\s*{\s*"name"\s*:\s*"inlist\([^)]*\)"
  /x

  settings.get_features.each do |feature|
    feature.get_rules_linked_campaign.each do |rule|
      segments = {}

      if [CampaignTypeEnum::PERSONALIZE, CampaignTypeEnum::ROLLOUT].include?(rule.get_type)
        segments = rule.get_variations[0].get_segments
      else
        segments = rule.get_segments
      end

      next unless segments

      json_segments = segments.to_json
      matches = json_segments.scan(pattern)

      if matches.any?
        feature.set_is_gateway_service_required(true)
        break
      end
    end
  end
end
