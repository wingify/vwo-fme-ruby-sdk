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

require_relative '../models/campaign/campaign_model'
require_relative '../models/campaign/feature_model'
require_relative '../models/settings/settings_model'
require_relative '../models/user/context_model'
require_relative '../services/storage_service'
require_relative './data_type_util'
require_relative './decision_util'
require_relative './network_util'
require_relative './impression_util'

# Evaluates the rules for a given campaign and feature based on the provided context.
#
# @param settings [SettingsModel] The settings configuration for evaluation.
# @param feature [FeatureModel] The feature being evaluated.
# @param campaign [CampaignModel] The campaign associated with the feature.
# @param context [ContextModel] The user context for evaluation.
# @param evaluated_feature_map [Hash] A hash of evaluated features.
# @param meg_group_winner_campaigns [Hash] A hash of MEG group winner campaigns.
# @param storage_service [StorageService] The storage service for persistence.
# @param decision [Hash] The decision object that will be updated based on the evaluation.
# @return [Hash] A hash containing the result of the pre-segmentation and the whitelisted object.
def evaluate_rule(settings, feature, campaign, context, evaluated_feature_map, meg_group_winner_campaigns, storage_service, decision)
  # Perform whitelisting and pre-segmentation checks
  pre_segmentation_result, whitelisted_object = DecisionUtil.check_whitelisting_and_pre_seg(
    settings, feature, campaign, context, evaluated_feature_map, meg_group_winner_campaigns, storage_service, decision
  )

  # If pre-segmentation is successful and a whitelisted object exists, proceed to send an impression
  if pre_segmentation_result && whitelisted_object.is_a?(Hash) && !whitelisted_object.empty?
    # Update the decision object with campaign and variation details
    decision.merge!(
      experiment_id: campaign.get_id,
      experiment_key: campaign.get_key,
      experiment_variation_id: whitelisted_object[:variation_id]
    )

    # Send an impression for the variation shown
    create_and_send_impression_for_variation_shown(settings, campaign.get_id, whitelisted_object[:variation_id], context)
  end

  # Return the results of the evaluation
  { pre_segmentation_result: pre_segmentation_result, whitelisted_object: whitelisted_object, updated_decision: decision }
end
