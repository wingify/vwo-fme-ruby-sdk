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

require_relative '../constants/constants'
require_relative '../decorators/storage_decorator'
require_relative '../enums/campaign_type_enum'
require_relative '../models/campaign/campaign_model'
require_relative '../models/campaign/feature_model'
require_relative '../models/campaign/variation_model'
require_relative '../models/settings/settings_model'
require_relative '../models/user/context_model'
require_relative '../packages/decision_maker/decision_maker'
require_relative '../services/campaign_decision_service'
require_relative '../services/storage_service'
require_relative './rule_evaluation_util'
require_relative './campaign_util'
require_relative './data_type_util'
require_relative './decision_util'
require_relative './function_util'
require_relative '../services/logger_service'
require_relative '../enums/log_level_enum'

# Evaluates groups for a given feature and group ID.
# @param settings [SettingsModel] The settings for the VWO instance
# @param feature [FeatureModel] The feature to evaluate
# @param group_id [String] The group ID to evaluate
# @param evaluated_feature_map [Hash] The map of evaluated features
# @param context [ContextModel] The context for the evaluation
# @param storage_service [StorageService] The storage service for the evaluation
def evaluate_groups(settings, feature, group_id, evaluated_feature_map, context, storage_service)
  feature_to_skip = []
  campaign_map = {}

  # Get all feature keys and campaignIds from the groupId
  feature_keys, group_campaign_ids = get_feature_keys_from_group(settings, group_id)

  feature_keys.each do |feature_key|
    temp_feature = get_feature_from_key(settings, feature_key)

    next if feature_to_skip.include?(feature_key)

    # Evaluate the feature rollout rules
    is_rollout_rule_passed = is_rollout_rule_for_feature_passed(settings, temp_feature, evaluated_feature_map, feature_to_skip, storage_service, context)
    if is_rollout_rule_passed
      settings.get_features.each do |current_feature|
        if current_feature.key == feature_key
          current_feature.get_rules_linked_campaign.each do |rule|
            if group_campaign_ids.include?(rule.id.to_s) || group_campaign_ids.include?("#{rule.id}_#{rule.variations[0].id}")
              campaign_map[feature_key] ||= []
              # Check if the campaign is already present in the campaignMap for the feature
              if campaign_map[feature_key].find_index { |item| item.rule_key == rule.rule_key }.nil?
                campaign_map[feature_key] << rule
              end
            end
          end
        end
      end
    end
  end

  eligible_campaigns, eligible_campaigns_with_storage = get_eligible_campaigns(settings, campaign_map, context, storage_service)

  find_winner_campaign_among_eligible_campaigns(settings, feature.key, eligible_campaigns, eligible_campaigns_with_storage, group_id, context, storage_service)
end

# Get the feature keys from the group
# @param settings [SettingsModel] The settings for the VWO instance
# @param group_id [String] The group ID to get the feature keys from
# @return [Array] The feature keys and the group campaign IDs
def get_feature_keys_from_group(settings, group_id)
  group_campaign_ids = CampaignUtil.get_campaigns_by_group_id(settings, group_id)
  feature_keys = CampaignUtil.get_feature_keys_from_campaign_ids(settings, group_campaign_ids)

  return feature_keys, group_campaign_ids
end

# Check if the rollout rule for the feature is passed
# @param settings [SettingsModel] The settings for the VWO instance
# @param feature [FeatureModel] The feature to check the rollout rule for
# @param evaluated_feature_map [Hash] The map of evaluated features
# @param feature_to_skip [Array] The list of features to skip
# @param storage_service [StorageService] The storage service for the evaluation
# @param context [ContextModel] The context for the evaluation
def is_rollout_rule_for_feature_passed(settings, feature, evaluated_feature_map, feature_to_skip, storage_service, context)
  return true if evaluated_feature_map.key?(feature.key) && evaluated_feature_map[feature.key].key?(:rollout_id)

  rollout_rules = get_specific_rules_based_on_type(feature, CampaignTypeEnum::ROLLOUT)

  if rollout_rules.any?
    rule_to_test_for_traffic = nil
    rollout_rules.each do |rule|
      result = evaluate_rule(settings, feature, rule, context, evaluated_feature_map, nil, storage_service, {})
      if result[:pre_segmentation_result]
        rule_to_test_for_traffic = rule
        break
      end
    end

    if rule_to_test_for_traffic
      campaign = CampaignModel.new.model_from_dictionary(rule_to_test_for_traffic)
      variation = evaluate_traffic_and_get_variation(settings, campaign, context.id)
      if variation.is_a?(VariationModel) && !variation.nil? && variation.id.is_a?(Integer)
        evaluated_feature_map[feature.key] = {
          rollout_id: rule_to_test_for_traffic.id,
          rollout_key: rule_to_test_for_traffic.key,
          rollout_variation_id: rule_to_test_for_traffic.variations[0].id
        }
        return true
      end
    end

    # No rollout rule passed
    feature_to_skip.push(feature.key)
    return false
  end

  # No rollout rule, evaluate experiments
  LoggerService.log(LogLevelEnum::INFO, "MEG_SKIP_ROLLOUT_EVALUATE_EXPERIMENTS", { featureKey: feature.key })
  return true
end

# Get the eligible campaigns
# @param settings [SettingsModel] The settings for the VWO instance
# @param campaign_map [Hash] The map of campaigns
# @param context [ContextModel] The context for the evaluation
# @param storage_service [StorageService] The storage service for the evaluation
def get_eligible_campaigns(settings, campaign_map, context, storage_service)
  eligible_campaigns = []
  eligible_campaigns_with_storage = []
  ineligible_campaigns = []

  campaign_map.each do |feature_key, campaigns|
    campaigns.each do |campaign|
      stored_data = StorageDecorator.new.get_feature_from_storage(feature_key, context, storage_service)

      if stored_data && stored_data[:experiment_variation_id]
        if stored_data[:experiment_key] == campaign.key
          variation = CampaignUtil.get_variation_from_campaign_key(settings, stored_data[:experiment_key], stored_data[:experiment_variation_id])
          if variation
            LoggerService.log(LogLevelEnum::INFO, "MEG_CAMPAIGN_FOUND_IN_STORAGE", { campaignKey: stored_data[:experiment_key], userId: context.id })

            unless eligible_campaigns_with_storage.any? { |item| item.key == campaign.key }
              eligible_campaigns_with_storage.push(campaign)
            end
            next
          end
        end
      end

      # Check if user is eligible for the campaign
      if CampaignDecisionService.new.get_pre_segmentation_decision(campaign, context) && CampaignDecisionService.new.is_user_part_of_campaign(context.id, campaign)
        LoggerService.log(LogLevelEnum::INFO, "MEG_CAMPAIGN_ELIGIBLE", { campaignKey: campaign.key, userId: context.id })

        eligible_campaigns.push(campaign)
        next
      end

      ineligible_campaigns.push(campaign)
    end
  end

  return eligible_campaigns, eligible_campaigns_with_storage
end

# Find the winner campaign among the eligible campaigns
# @param settings [SettingsModel] The settings for the VWO instance
# @param feature_key [String] The key of the feature
# @param eligible_campaigns [Array] The list of eligible campaigns
# @param eligible_campaigns_with_storage [Array] The list of eligible campaigns with storage
# @param group_id [String] The ID of the group
def find_winner_campaign_among_eligible_campaigns(settings, feature_key, eligible_campaigns, eligible_campaigns_with_storage, group_id, context, storage_service)
  winner_campaign = nil
  campaign_ids = CampaignUtil.get_campaign_ids_from_feature_key(settings, feature_key)
  meg_algo_number = settings.get_groups[group_id.to_s][:et.to_s] || Constants::RANDOM_ALGO

  # Check eligible_campaigns_with_storage first
  if eligible_campaigns_with_storage.length == 1
    winner_campaign = eligible_campaigns_with_storage[0]
    LoggerService.log(LogLevelEnum::INFO, "MEG_WINNER_CAMPAIGN", { campaignKey: winner_campaign.key, groupId: group_id, userId: context.id, algo: 'using random algorithm' })
  elsif eligible_campaigns_with_storage.length > 1 && meg_algo_number == Constants::RANDOM_ALGO
    winner_campaign = normalize_weights_and_find_winning_campaign(eligible_campaigns_with_storage, context, campaign_ids, group_id, storage_service)
  elsif eligible_campaigns_with_storage.length > 1
    winner_campaign = get_campaign_using_advanced_algo(settings, eligible_campaigns_with_storage, context, campaign_ids, group_id, storage_service)
  end

  # Fallback to eligible_campaigns if no winner found in storage
  if eligible_campaigns_with_storage.empty?
    if eligible_campaigns.length == 1
      winner_campaign = eligible_campaigns[0]
      LoggerService.log(LogLevelEnum::INFO, "MEG_WINNER_CAMPAIGN", { campaignKey: winner_campaign.key, groupId: group_id, userId: context.id, algo: 'using random algorithm' })
    elsif eligible_campaigns.length > 1 && meg_algo_number == Constants::RANDOM_ALGO
      winner_campaign = normalize_weights_and_find_winning_campaign(eligible_campaigns, context, campaign_ids, group_id, storage_service)
    elsif eligible_campaigns.length > 1
      winner_campaign = get_campaign_using_advanced_algo(settings, eligible_campaigns, context, campaign_ids, group_id, storage_service)
    else
      LoggerService.log(LogLevelEnum::INFO, "No winner campaign found for MEG group: #{group_id}", nil)
    end
  end

  winner_campaign
end

# Helper for random allocation winner selection
# @param shortlisted_campaigns [Array] The list of shortlisted campaigns
# @param context [ContextModel] The context for the evaluation
# @param called_campaign_ids [Array] The list of called campaign IDs
# @param group_id [String] The ID of the group
# @param storage_service [StorageService] The storage service for the evaluation
def normalize_weights_and_find_winning_campaign(shortlisted_campaigns, context, called_campaign_ids, group_id, storage_service)
  # Convert to VariationModel first and then normalize weights
  shortlisted_variations = shortlisted_campaigns.map do |campaign|
    variation = VariationModel.new.model_from_dictionary(campaign)
    variation.weight = (100.0 / shortlisted_campaigns.length).round(4)
    variation
  end

  # Set campaign allocation
  CampaignUtil.set_campaign_allocation(shortlisted_variations)

  winner_campaign = CampaignDecisionService.new.get_variation(
    shortlisted_variations,
    DecisionMaker.new.calculate_bucket_value(CampaignUtil.get_bucketing_seed(context.id, nil, group_id))
  )

  if winner_campaign
    campaign_key = winner_campaign.type == CampaignTypeEnum::AB ? 
      winner_campaign.key : 
      "#{winner_campaign.key}_#{winner_campaign.rule_key}"

    LoggerService.log(
      LogLevelEnum::INFO,
      "MEG_WINNER_CAMPAIGN",
      {
        campaignKey: campaign_key,
        groupId: group_id,
        userId: context.id,
        algo: 'using random algorithm'
      }
    )

    StorageDecorator.new.set_data_in_storage(
      {
        feature_key: "#{Constants::VWO_META_MEG_KEY}#{group_id}",
        context: context,
        experiment_id: winner_campaign.id,
        experiment_key: winner_campaign.key,
        experiment_variation_id: winner_campaign.type == CampaignTypeEnum::PERSONALIZE ? winner_campaign.variations[0].id : -1
      },
      storage_service
    )

    return winner_campaign if called_campaign_ids.include?(winner_campaign.id)
  else
    LoggerService.log(LogLevelEnum::INFO, "No winner campaign found for MEG group: #{group_id}, using random algorithm", nil)
  end

  nil
end

# Advanced algorithm for campaign selection
# @param settings [SettingsModel] The settings for the VWO instance
# @param shortlisted_campaigns [Array] The list of shortlisted campaigns
# @param context [ContextModel] The context for the evaluation
# @param called_campaign_ids [Array] The list of called campaign IDs
# @param group_id [String] The ID of the group
# @param storage_service [StorageService] The storage service for the evaluation
def get_campaign_using_advanced_algo(settings, shortlisted_campaigns, context, called_campaign_ids, group_id, storage_service)
  winner_campaign = nil
  found = false
  priority_order = settings.get_groups[group_id.to_s][:p.to_s] || []
  weights = settings.get_groups[group_id.to_s][:wt.to_s] || {}

  # Check priority order first
  priority_order.each do |priority|
    shortlisted_campaigns.each do |campaign|
      if campaign.id.to_s == priority.to_s || "#{campaign.id}_#{campaign.variations[0].id}" == priority
        winner_campaign = campaign.clone
        found = true
        break
      end
    end
    break if found
  end

  # If no winner found through priority, try weighted distribution
  if winner_campaign.nil?
    participating_campaign_list = shortlisted_campaigns.map do |campaign|
      campaign_id = campaign.id.to_s
      weight = weights[campaign_id] || weights["#{campaign_id}_#{campaign.variations[0].id}"]
      next nil unless weight

      cloned_campaign = campaign.clone
      variation = VariationModel.new.model_from_dictionary(cloned_campaign)
      variation.weight = weight
      variation
    end.compact  # Remove nil values

    # Convert to VariationModel and set allocations
    CampaignUtil.set_campaign_allocation(participating_campaign_list)
    winner_campaign = CampaignDecisionService.new.get_variation(
      participating_campaign_list,
      DecisionMaker.new.calculate_bucket_value(CampaignUtil.get_bucketing_seed(context.id, nil, group_id))
    )
  end

  if winner_campaign
    campaign_key = winner_campaign.type == CampaignTypeEnum::AB ? 
      winner_campaign.key : 
      "#{winner_campaign.key}_#{winner_campaign.rule_key}"
    
    LoggerService.log(
      LogLevelEnum::INFO,
      "MEG_WINNER_CAMPAIGN",
      {
        campaignKey: campaign_key,
        groupId: group_id,
        userId: context.id,
        algo: 'using advanced algorithm'
      }
    )

    StorageDecorator.new.set_data_in_storage(
      {
        feature_key: "#{Constants::VWO_META_MEG_KEY}#{group_id}",
        context: context,
        experiment_id: winner_campaign.id,
        experiment_key: winner_campaign.key,
        experiment_variation_id: winner_campaign.type == CampaignTypeEnum::PERSONALIZE ? winner_campaign.variations[0].id : -1
      },
      storage_service
    )
    
    return winner_campaign if called_campaign_ids.include?(winner_campaign.id)
  else
    LoggerService.log(LogLevelEnum::INFO, "No winner campaign found for MEG group: #{group_id}, using advanced algorithm", nil)
  end

  nil
end