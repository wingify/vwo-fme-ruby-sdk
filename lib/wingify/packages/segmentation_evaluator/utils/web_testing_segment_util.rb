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
require_relative '../../../enums/api_enum'
require_relative '../../../services/logger_service'
require_relative '../../../enums/log_level_enum'
require_relative '../../../utils/data_type_util'

module WebTestingSegmentUtil
  class << self
    # Normalizes Web Testing campaign map keys and variation values to strings.
    # @param raw_assignments [Hash] The raw assignments map from the context.
    # @return [Hash] The normalized assignments map with campaign_id as key and variation_id as value.
    def normalize_web_testing_campaigns_map(raw_assignments)
      campaign_id_to_variation_id = {}
      raw_assignments.each do |campaign_id, assigned_variation_id|
        unless assigned_variation_id.nil? || campaign_id.to_s.empty?
          campaign_id_to_variation_id[campaign_id.to_s] = assigned_variation_id.to_s
        end
      end
      campaign_id_to_variation_id
    end

    # Parses `context.platform_variables[:webTestingCampaigns]` (JSON string or plain object).
    # @param context [ContextModel]
    # @return [Hash, nil]
    def parse_web_testing_campaigns_from_context(context)
      platform_variables = context.get_platform_variables || {}
      # support both string and symbol keys
      web_testing_campaigns_input = platform_variables[:webTestingCampaigns] || platform_variables['webTestingCampaigns']

      if web_testing_campaigns_input.nil?
        return nil
      end

      if web_testing_campaigns_input.is_a?(Hash)
        return normalize_web_testing_campaigns_map(web_testing_campaigns_input)
      end

      if web_testing_campaigns_input.is_a?(String)
        trimmed_json = web_testing_campaigns_input.strip
        if trimmed_json.empty?
          return nil
        end

        begin
          # Check for duplicate keys using regex
          all_campaign_id_tokens = trimmed_json.scan(/"([^"\\]*)"\s*:/).flatten
          if all_campaign_id_tokens.any?
            campaign_ids = all_campaign_id_tokens
            has_duplicate_campaign_id = campaign_ids.length != campaign_ids.uniq.length
            if has_duplicate_campaign_id
              LoggerService.log(
                LogLevelEnum::ERROR,
                'INVALID_WEB_TESTING_CAMPAIGNS_DUPLICATE_KEY',
                { an: ApiEnum::GET_FLAG, uuid: context.get_uuid, sId: context.get_session_id }
              )
            end
          end

          parsed_assignments = JSON.parse(trimmed_json)
          if parsed_assignments.is_a?(Hash)
            return normalize_web_testing_campaigns_map(parsed_assignments)
          end

          LoggerService.log(
            LogLevelEnum::ERROR,
            'INVALID_WEB_TESTING_CAMPAIGNS_JSON',
            { an: ApiEnum::GET_FLAG, uuid: context.get_uuid, sId: context.get_session_id }
          )
        rescue JSON::ParserError
          LoggerService.log(
            LogLevelEnum::ERROR,
            'INVALID_WEB_TESTING_CAMPAIGNS_JSON',
            { an: ApiEnum::GET_FLAG, uuid: context.get_uuid, sId: context.get_session_id }
          )
        end
        return nil
      end

      # For array, numeric, boolean etc.
      kind = web_testing_campaigns_input.is_a?(Array) ? 'array' : DataTypeUtil.get_type(web_testing_campaigns_input).downcase
      LoggerService.log(
        LogLevelEnum::ERROR,
        'INVALID_WEB_TESTING_CAMPAIGNS_TYPE',
        { kind: kind, an: ApiEnum::GET_FLAG, uuid: context.get_uuid, sId: context.get_session_id }
      )
      nil
    end

    # Evaluates campaignVariation operand encoding:
    # - "!C" — user is not in campaign C (no entry in map)
    # - "C_!V" — user is in campaign C and assigned variation is not V
    # - "C_V" — user is in campaign C with variation V
    # - "C" (digits only) — user is in campaign C (any variation)
    def evaluate_web_testing_campaign_variation(campaign_variation_operand, assigned_variations_by_campaign_id)
      assignments = assigned_variations_by_campaign_id || {}

      # match type !C
      if match = /^!(\d+)$/.match(campaign_variation_operand)
        campaign_id = match[1]
        return { result: !assignments.key?(campaign_id), invalid_format: false }
      end

      # match type C_!V
      if match = /^(\d+)_!(\d+)$/.match(campaign_variation_operand)
        campaign_id = match[1]
        variation_id = match[2]
        if !assignments.key?(campaign_id)
          return { result: false, invalid_format: false }
        end
        return { result: assignments[campaign_id] != variation_id, invalid_format: false }
      end
      
      # match type C_V
      if match = /^(\d+)_(\d+)$/.match(campaign_variation_operand)
        campaign_id = match[1]
        variation_id = match[2]
        if !assignments.key?(campaign_id)
          return { result: false, invalid_format: false }
        end
        return { result: assignments[campaign_id] == variation_id, invalid_format: false }
      end
      
      # match type C
      if match = /^(\d+)$/.match(campaign_variation_operand)
        campaign_id = match[1]
        return { result: assignments.key?(campaign_id), invalid_format: false }
      end

      { result: false, invalid_format: true }
    end
  end
end
