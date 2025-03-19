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

require_relative '../packages/decision_maker/decision_maker'
require_relative '../services/logger_service'
require_relative '../enums/log_level_enum'
require_relative '../packages/segmentation_evaluator/core/segmentation_manager'

require_relative '../constants/constants'
require_relative '../models/campaign/variation_model'
require_relative '../models/campaign/campaign_model'
require_relative '../models/user/context_model'
require_relative '../enums/campaign_type_enum'
require_relative '../utils/data_type_util'
require_relative '../utils/log_message_util'

class CampaignDecisionService
  # Determines if a user is part of a campaign based on bucketing logic
  # @param user_id [String] The ID of the user
  # @param campaign [CampaignModel] The campaign to check
  # @return [Boolean] True if the user is part of the campaign, false otherwise
  def is_user_part_of_campaign(user_id, campaign)
    return false if campaign.nil? || user_id.nil?

    is_rollout_or_personalize = [CampaignTypeEnum::ROLLOUT, CampaignTypeEnum::PERSONALIZE].include?(campaign.get_type)
    salt = is_rollout_or_personalize ? campaign.get_variations.first.get_salt : campaign.get_salt
    traffic_allocation = is_rollout_or_personalize ? campaign.get_variations.first.get_weight : campaign.get_traffic

    bucket_key = salt ? "#{salt}_#{user_id}" : "#{campaign.get_id}_#{user_id}"
    value_assigned_to_user = DecisionMaker.new.get_bucket_value_for_user(bucket_key)

    is_user_part = value_assigned_to_user != 0 && value_assigned_to_user <= traffic_allocation

    LoggerService.log(LogLevelEnum::INFO, "USER_PART_OF_CAMPAIGN", {
      userId: user_id,
      notPart: is_user_part ? '' : 'not',
      campaignKey: campaign.get_type == CampaignTypeEnum::AB ? campaign.get_key : "#{campaign.get_name}_#{campaign.get_rule_key}"
    })

    is_user_part
  end

  # Returns the variation assigned to a user based on bucket value
  # @param variations [Array<VariationModel>] The variations to check
  # @param bucket_value [Integer] The bucket value to check
  # @return [VariationModel] The variation assigned to the user
  def get_variation(variations, bucket_value)
    variations.find { |variation| bucket_value >= variation.get_start_range_variation && bucket_value <= variation.get_end_range_variation }
  end

  # Checks if the bucket value is in the range of the variation
  # @param variation [VariationModel] The variation to check
  # @param bucket_value [Integer] The bucket value to check
  # @return [VariationModel] The variation if the bucket value is in the range, nil otherwise
  def check_in_range(variation, bucket_value)
    variation if bucket_value >= variation.get_start_range_variation && bucket_value <= variation.get_end_range_variation
  end

  # Buckets a user into a variation for a given campaign
  # @param user_id [String] The ID of the user
  # @param account_id [String] The ID of the account
  # @param campaign [CampaignModel] The campaign to bucket the user into
  # @return [VariationModel] The variation assigned to the user
  def bucket_user_to_variation(user_id, account_id, campaign)
    return nil if campaign.nil? || user_id.nil?

    multiplier = campaign.get_traffic ? 1 : nil
    percent_traffic = campaign.get_traffic
    salt = campaign.get_salt
    bucket_key = salt ? "#{salt}_#{account_id}_#{user_id}" : "#{campaign.get_id}_#{account_id}_#{user_id}"
    
    hash_value = DecisionMaker.new.generate_hash_value(bucket_key)
    bucket_value = DecisionMaker.new.generate_bucket_value(hash_value, Constants::MAX_TRAFFIC_VALUE, multiplier)

    LoggerService.log(LogLevelEnum::DEBUG, "USER_BUCKET_TO_VARIATION", {
      userId: user_id,
      campaignKey: campaign.get_key,
      percentTraffic: percent_traffic,
      bucketValue: bucket_value,
      hashValue: hash_value
    })

    get_variation(campaign.get_variations, bucket_value)
  end

  # Pre-segmentation decision based on user context and campaign rules
  # @param campaign [CampaignModel] The campaign to evaluate
  # @param context [ContextModel] The context for the evaluation
  # @return [Boolean] True if the user satisfies the campaign rules, false otherwise
  def get_pre_segmentation_decision(campaign, context)
    campaign_type = campaign.get_type
    segments = if [CampaignTypeEnum::ROLLOUT, CampaignTypeEnum::PERSONALIZE].include?(campaign_type)
                 campaign.get_variations.first.get_segments
               elsif campaign_type == CampaignTypeEnum::AB
                 campaign.get_segments
               end

    if DataTypeUtil.is_object(segments) && segments.empty?
      LoggerService.log(LogLevelEnum::INFO, "SEGMENTATION_SKIP", {
        userId: context.get_id,
        campaignKey: campaign.get_type == CampaignTypeEnum::AB ? campaign.get_key : "#{campaign.get_name}_#{campaign.get_rule_key}"
      })
      return true
    else
      pre_segmentation_result = SegmentationManager.instance.validate_segmentation(segments, context.get_custom_variables)

      if !pre_segmentation_result
        LoggerService.log(LogLevelEnum::INFO, "SEGMENTATION_STATUS", {
          userId: context.get_id,
          campaignKey: campaign.get_type == CampaignTypeEnum::AB ? campaign.get_key : "#{campaign.get_name}_#{campaign.get_rule_key}",
          status: 'failed'
        })
        return false
      end

      LoggerService.log(LogLevelEnum::INFO, "SEGMENTATION_STATUS", {
        userId: context.get_id,
        campaignKey: campaign.get_type == CampaignTypeEnum::AB ? campaign.get_key : "#{campaign.get_name}_#{campaign.get_rule_key}",
        status: 'passed'
      })

      return true
    end
  end

  # Determines the variation assigned to a user for a campaign
  # @param user_id [String] The ID of the user
  # @param account_id [String] The ID of the account
  # @param campaign [CampaignModel] The campaign to evaluate
  # @return [VariationModel] The variation assigned to the user
  def get_variation_alloted(user_id, account_id, campaign)
    is_user_part = is_user_part_of_campaign(user_id, campaign)

    if [CampaignTypeEnum::ROLLOUT, CampaignTypeEnum::PERSONALIZE].include?(campaign.get_type)
      return campaign.get_variations.first if is_user_part
    else
      return bucket_user_to_variation(user_id, account_id, campaign) if is_user_part
    end

    nil
  end
end
