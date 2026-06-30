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

require_relative '../evaluators/segment_evaluator'
require_relative '../../../models/settings/settings_model'
require_relative '../../../utils/gateway_service_util'
require_relative '../../../enums/url_enum'
require_relative '../../../services/logger_service'
require_relative '../../../models/user/context_model'
require_relative '../../../models/campaign/feature_model'
require_relative '../../../models/user/context_vwo_model'
require_relative '../../../services/settings_service'
require_relative '../../../utils/data_type_util'
require_relative '../../../enums/log_level_enum'
require_relative '../../../enums/api_enum'
require_relative '../enums/segment_operator_value_enum'

class SegmentationManager
  @@instance = nil # Singleton instance

  attr_accessor :evaluator

  def self.instance
    @@instance ||= SegmentationManager.new
  end

  def initialize
    @evaluator = SegmentEvaluator.new
  end

  def attach_evaluator(evaluator = nil)
    @evaluator = evaluator || SegmentEvaluator.new
  end

  # Set the context for the segmentation evaluator
  # @param settings [SettingsModel] The settings model
  # @param feature [FeatureModel] The feature model
  # @param context [ContextModel] The context model
  def set_contextual_data(settings, feature, context)
    attach_evaluator
    @evaluator.settings = settings
    @evaluator.context = context
    @evaluator.feature = feature

    # If both user agent and IP address are null, avoid making a gateway service call
    return if context&.get_user_agent.nil? && context&.get_ip_address.nil?

    if feature.get_is_gateway_service_required
      if SettingsService.instance.is_gateway_service_provided && (context.get_vwo.nil?)
        query_params = {}
        query_params['userAgent'] = context.get_user_agent if context&.get_user_agent
        query_params['ipAddress'] = context.get_ip_address if context&.get_ip_address

        begin
          params = get_query_params(query_params)
          vwo_data = get_from_gateway_service(params, UrlEnum::GET_USER_DATA)
          context.set_vwo(ContextVWOModel.new.model_from_dictionary(vwo_data))
        rescue StandardError => e
          LoggerService.log(LogLevelEnum::ERROR, "ERROR_SETTING_SEGMENTATION_CONTEXT", { err: e.message, an: ApiEnum::GET_FLAG, sId: context.get_session_id, uuid: context.get_uuid})
        end
      end
    end
  end

  def validate_segmentation(dsl, properties)
    if has_campaign_variation_node?(dsl)
      platform_vars = @evaluator.context&.get_platform_variables
      web_testing_campaigns = platform_vars && (platform_vars[:webTestingCampaigns] || platform_vars['webTestingCampaigns'])
      return false unless web_testing_campaigns
    end

    @evaluator.is_segmentation_valid(dsl, properties)
  end

  private

  # Checks if the provided DSL contains a campaign variation node.
  # This is used to determine if web testing pre-segmentation should be evaluated.
  #
  # @param dsl [Hash] The DSL (Domain Specific Language) representing the segmentation rules.
  # @return [Boolean] Returns true if a web campaign variation node is found, false otherwise.
  def has_campaign_variation_node?(dsl)
    # Return false immediately if the DSL is not a hash
    return false unless dsl.is_a?(Hash)

    # Iterate through each operator and operand in the DSL
    dsl.each do |operator, operand|
      # Check if the current operator matches the web campaign variation operator
      return true if operator.to_s == SegmentOperatorValueEnum::WEB_CAMPAIGN_VARIATION

      # If the operand is an array, recursively check each sub-DSL within it
      if operand.is_a?(Array)
        operand.each do |sub_dsl|
          return true if has_campaign_variation_node?(sub_dsl)
        end
      # If the operand is a hash, recursively check the hash itself
      elsif operand.is_a?(Hash)
        return true if has_campaign_variation_node?(operand)
      end
    end
    
    # Return false if no campaign variation node is found in the entire DSL structure
    false
  end
end
