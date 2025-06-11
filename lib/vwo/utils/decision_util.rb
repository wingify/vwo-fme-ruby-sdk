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

require_relative '../enums/campaign_type_enum'
require_relative '../enums/status_enum'
require_relative '../models/campaign/campaign_model'
require_relative '../models/campaign/feature_model'
require_relative '../models/campaign/variation_model'
require_relative '../models/settings/settings_model'
require_relative '../models/user/context_model'
require_relative '../packages/decision_maker/decision_maker'
require_relative '../packages/segmentation_evaluator/core/segmentation_manager'
require_relative '../services/campaign_decision_service'
require_relative '../services/storage_service'
require_relative '../utils/data_type_util'
require_relative '../constants/constants'
require_relative '../utils/campaign_util'
require_relative '../utils/function_util'
require_relative '../utils/meg_util'
require_relative '../utils/uuid_util'
require_relative '../decorators/storage_decorator'
require_relative '../services/logger_service'
require_relative '../enums/log_level_enum'

class DecisionUtil
  # Check if the campaign satisfies whitelisting and pre-segmentation
  # @param settings [SettingsModel] The settings for the VWO instance
  # @param feature [FeatureModel] The feature to evaluate
  # @param campaign [CampaignModel] The campaign to evaluate
  # @param context [ContextModel] The context for the evaluation
  # @param evaluated_feature_map [Hash] The map of evaluated features
  # @param meg_group_winner_campaigns [Hash] The map of MEG group winner campaigns
  def self.check_whitelisting_and_pre_seg(settings, feature, campaign, context, evaluated_feature_map, meg_group_winner_campaigns, storage_service, decision)
    vwo_user_id = UUIDUtil.get_uuid(context.get_id, settings.get_account_id)
    campaign_id = campaign.get_id

    if campaign.get_type == CampaignTypeEnum::AB
      # Set _vwoUserId for variation targeting variables
      variation_targeting_vars = context.get_variation_targeting_variables || {}
      variation_targeting_vars["_vwoUserId"] = campaign.get_is_user_list_enabled ? vwo_user_id : context.get_id
      context.set_variation_targeting_variables(variation_targeting_vars)
      decision[:variation_targeting_variables] = variation_targeting_vars

      # Check for whitelisting
      if campaign.get_is_forced_variation_enabled
        whitelisted_variation = check_campaign_whitelisting(campaign, context)
        return [true, whitelisted_variation] if whitelisted_variation && !whitelisted_variation.empty?
      else
        LoggerService.log(LogLevelEnum::INFO, "WHITELISTING_SKIP", {
          campaignKey: campaign.get_rule_key,
          userId: context.get_id
        })
      end
    end

    # User list segment check for campaign pre-segmentation
    custom_vars = context.get_custom_variables || {}
    custom_vars["_vwoUserId"] = campaign.get_is_user_list_enabled ? vwo_user_id : context.get_id
    context.set_custom_variables(custom_vars)
    decision[:custom_variables] = custom_vars

    # Check if rule belongs to Mutually Exclusive Group (MEG)
    group_details = CampaignUtil.get_group_details_if_campaign_part_of_it(settings, campaign_id, campaign.get_type == CampaignTypeEnum::PERSONALIZE ? campaign.get_variations[0].get_id : nil)
    group_id = group_details[:group_id]

    # Check if the group has already been evaluated
    group_winner_campaign_id = meg_group_winner_campaigns[group_id] if meg_group_winner_campaigns && meg_group_winner_campaigns.key?(group_id)
    return evaluate_meg_campaign(group_winner_campaign_id, campaign, context, meg_group_winner_campaigns, group_id) if group_winner_campaign_id

    # Check in storage if the group was already evaluated
    stored_data = StorageDecorator.new.get_feature_from_storage("#{Constants::VWO_META_MEG_KEY}#{group_id}", context, storage_service)
    if stored_data && stored_data[:experiment_key] && stored_data[:experiment_id]
      LoggerService.log(LogLevelEnum::INFO, "MEG_CAMPAIGN_FOUND_IN_STORAGE", {
        campaignKey: stored_data[:experiment_key],
        userId: context.get_id
      })

      if stored_data[:experiment_id] == campaign_id
        return evaluate_meg_personalization(campaign, stored_data, meg_group_winner_campaigns, group_id)
      end
      meg_group_winner_campaigns[group_id] = stored_data[:experiment_variation_id] != -1 ? "#{stored_data[:experiment_id]}_#{stored_data[:experiment_variation_id]}" : stored_data[:experiment_id]
      return [false, nil]
    end

    # Pre-segmentation check
    pre_segmentation_passed = CampaignDecisionService.new.get_pre_segmentation_decision(campaign, context)

    if pre_segmentation_passed && group_id
      winner_campaign = evaluate_groups(settings, feature, group_id, evaluated_feature_map, context, storage_service)
      return evaluate_meg_campaign_winner(winner_campaign, campaign, context, meg_group_winner_campaigns, group_id)
    end

    [pre_segmentation_passed, nil]
  end

  # Evaluate the MEG campaign
  # @param group_winner_campaign_id [String] The ID of the MEG group winner campaign
  # @param campaign [CampaignModel] The campaign to evaluate
  # @param context [ContextModel] The context for the evaluation
  # @param meg_group_winner_campaigns [Hash] The map of MEG group winner campaigns
  # @param group_id [String] The ID of the MEG group
  def self.evaluate_meg_campaign(group_winner_campaign_id, campaign, context, meg_group_winner_campaigns, group_id)
    if campaign.get_type == CampaignTypeEnum::AB && group_winner_campaign_id == campaign.get_id
      return [true, nil]
    elsif campaign.get_type == CampaignTypeEnum::PERSONALIZE && group_winner_campaign_id == "#{campaign.get_id}_#{campaign.get_variations[0].get_id}"
      return [true, nil]
    end
    [false, nil]
  end

  def self.evaluate_meg_personalization(campaign, stored_data, meg_group_winner_campaigns, group_id)
    if campaign.get_type == CampaignTypeEnum::PERSONALIZE
      if stored_data[:experiment_variation_id] == campaign.get_variations[0].get_id
        return [true, nil]
      else
        meg_group_winner_campaigns[group_id] = "#{stored_data[:experiment_id]}_#{stored_data[:experiment_variation_id]}"
        return [false, nil]
      end
    else
      return [true, nil]
    end
  end

  # Evaluate the MEG campaign winner
  # @param winner_campaign [CampaignModel] The winner campaign
  # @param campaign [CampaignModel] The campaign to evaluate
  # @param context [ContextModel] The context for the evaluation
  # @param meg_group_winner_campaigns [Hash] The map of MEG group winner campaigns
  # @param group_id [String] The ID of the MEG group
  def self.evaluate_meg_campaign_winner(winner_campaign, campaign, context, meg_group_winner_campaigns, group_id)
    if winner_campaign && winner_campaign.get_id == campaign.get_id
      if winner_campaign.get_type == CampaignTypeEnum::AB
        return [true, nil]
      else
        # if personalise then check if the requested variation is the winner
        if winner_campaign.get_variations[0].get_id == campaign.get_variations[0].get_id
          return [true, nil]
        else
          meg_group_winner_campaigns[group_id] = "#{winner_campaign.get_id}_#{winner_campaign.get_variations[0].get_id}"
          return [false, nil]
        end
      end
    elsif winner_campaign
      if winner_campaign.get_type == CampaignTypeEnum::AB
        meg_group_winner_campaigns[group_id] = winner_campaign.get_id
      else
        meg_group_winner_campaigns[group_id] = "#{winner_campaign.get_id}_#{winner_campaign.get_variations[0].get_id}"
      end
      return [false, nil]
    end
    
    meg_group_winner_campaigns[group_id] = -1
    [false, nil]
  end

  # Evaluate the traffic and get the variation
  # @param settings [SettingsModel] The settings for the VWO instance
  # @param campaign [CampaignModel] The campaign to evaluate
  # @param user_id [String] The ID of the user
  def self.evaluate_traffic_and_get_variation(settings, campaign, user_id)
    variation = CampaignDecisionService.new.get_variation_alloted(user_id, settings.get_account_id, campaign)
    if variation.nil?
      LoggerService.log(LogLevelEnum::INFO, "USER_CAMPAIGN_BUCKET_INFO", {
        campaignKey: campaign.get_type == CampaignTypeEnum::AB ? campaign.get_key : "#{campaign.get_name}_#{campaign.get_rule_key}",
        userId: user_id,
        status: 'did not get any variation'
      })
      return nil
    end
    LoggerService.log(LogLevelEnum::INFO, "USER_CAMPAIGN_BUCKET_INFO", {
      campaignKey: campaign.get_type == CampaignTypeEnum::AB ? campaign.get_key : "#{campaign.get_name}_#{campaign.get_rule_key}",
      userId: user_id,
      status: "got variation: #{variation.get_key}"
    })
    variation
  end

  # Check if the campaign satisfies whitelisting
  # @param campaign [CampaignModel] The campaign to evaluate
  # @param context [ContextModel] The context for the evaluation
  def self.check_campaign_whitelisting(campaign, context)
    # Check if the campaign satisfies whitelisting
    whitelisting_result = evaluate_whitelisting(campaign, context)
    status = whitelisting_result ? StatusEnum::PASSED : StatusEnum::FAILED
    variation_string = whitelisting_result ? whitelisting_result[:variation].get_key : ''

    LoggerService.log(LogLevelEnum::INFO, "WHITELISTING_STATUS", {
      userId: context.get_id,
      campaignKey: campaign.get_type == CampaignTypeEnum::AB ? campaign.get_key : "#{campaign.get_name}_#{campaign.get_rule_key}",
      status: status,
      variationString: variation_string
    })

    whitelisting_result
  end

  # Evaluate the whitelisting
  # @param campaign [CampaignModel] The campaign to evaluate
  # @param context [ContextModel] The context for the evaluation
  def self.evaluate_whitelisting(campaign, context)
    targeted_variations = []
    
    campaign.get_variations.each do |variation|
      next if DataTypeUtil.is_object(variation.get_segments) && variation.get_segments.empty?
      if DataTypeUtil.is_object(variation.get_segments)
        segmentation_result = SegmentationManager.instance.validate_segmentation(
          variation.get_segments,
          context.get_variation_targeting_variables
        )

        targeted_variations.push(clone_object(variation)) if segmentation_result
      end
    end

    # Determine the whitelisted variation
    whitelisted_variation = nil
    if targeted_variations.length > 1
      scale_variation_weights(targeted_variations)
      current_allocation = 0

      targeted_variations.each do |variation|
        step_factor = assign_range_values(variation, current_allocation)
        current_allocation += step_factor
      end

      whitelisted_variation = CampaignDecisionService.new.get_variation(
        targeted_variations,
        DecisionMaker.new.calculate_bucket_value(CampaignUtil.get_bucketing_seed(context.get_id, campaign, nil))
      )
    else
      whitelisted_variation = targeted_variations.first
    end

    return nil unless whitelisted_variation

    {
      variation: whitelisted_variation,
      variation_name: whitelisted_variation.get_key,
      variation_id: whitelisted_variation.get_id
    }
  end
end
