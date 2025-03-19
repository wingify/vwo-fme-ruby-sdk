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
          LoggerService.log(LogLevelEnum::ERROR, "Error in setting contextual data for segmentation. Got error: #{e.message}", nil)
        end
      end
    end
  end

  def validate_segmentation(dsl, properties)
    @evaluator.is_segmentation_valid(dsl, properties)
  end
end
