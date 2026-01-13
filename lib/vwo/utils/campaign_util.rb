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

require_relative '../constants/constants'
require_relative '../enums/campaign_type_enum'
require_relative '../models/campaign/campaign_model'
require_relative '../models/campaign/feature_model'
require_relative '../models/campaign/variation_model'
require_relative '../models/settings/settings_model'
require_relative '../services/logger_service'
require_relative '../enums/log_level_enum'
require_relative '../models/campaign/rule_model'

module CampaignUtil
  # Sets the variation allocation for a campaign
  # @param campaign [CampaignModel] The campaign to set the variation allocation for
  def self.set_variation_allocation(campaign)
    if [CampaignTypeEnum::ROLLOUT, CampaignTypeEnum::PERSONALIZE].include?(campaign.get_type)
      handle_rollout_campaign(campaign)
    else
      current_allocation = 0
      campaign.get_variations.each do |variation|
        step_factor = assign_range_values(variation, current_allocation)
        current_allocation += step_factor

        LoggerService.log(LogLevelEnum::INFO, "VARIATION_RANGE_ALLOCATION", {
          variationKey: variation.get_key,
          campaignKey: campaign.get_key,
          variationWeight: variation.get_weight,
          startRange: variation.get_start_range_variation,
          endRange: variation.get_end_range_variation
        })
      end
    end
  end

  # Assigns start and end range values to a variation
  # @param variation [VariationModel] The variation to assign the start and end range values to
  # @param current_allocation [Integer] The current allocation
  # @return [Integer] The step factor
  def self.assign_range_values(variation, current_allocation)
    step_factor = get_variation_bucket_range(variation.get_weight)

    if step_factor > 0
      variation.set_start_range(current_allocation + 1)
      variation.set_end_range(current_allocation + step_factor)
    else
      variation.set_start_range(-1)
      variation.set_end_range(-1)
    end

    step_factor
  end

  # Scales variation weights to sum up to 100%
  # @param variations [Array<VariationModel>] The variations to scale the weights of
  # @return [Array<VariationModel>] The scaled variations
  def self.scale_variation_weights(variations)
    total_weight = variations.sum(&:weight)

    if total_weight.zero?
      equal_weight = 100.0 / variations.length
      variations.each { |variation| variation.weight = equal_weight }
    else
      variations.each { |variation| variation.weight = (variation.weight / total_weight) * 100 }
    end
  end

  # Generates a bucketing seed based on user ID and campaign
  # @param user_id [String] The ID of the user
  # @param campaign [CampaignModel] The campaign to generate the bucketing seed for
  # @param group_id [String] The ID of the group
  # @return [String] The bucketing seed
  def self.get_bucketing_seed(user_id, campaign, group_id = nil)
    return "#{group_id}_#{user_id}" if group_id

    is_rollout_or_personalize = [CampaignTypeEnum::ROLLOUT, CampaignTypeEnum::PERSONALIZE].include?(campaign.get_type)
    salt = is_rollout_or_personalize ? campaign.get_variations.first.get_salt : campaign.get_salt

    salt ? "#{salt}_#{user_id}" : "#{campaign.get_id}_#{user_id}"
  end

  # Retrieves variation from campaign key
  # @param settings [SettingsModel] The settings for the VWO instance
  # @param campaign_key [String] The key of the campaign
  # @param variation_id [Integer] The ID of the variation
  # @return [VariationModel] The variation
  def self.get_variation_from_campaign_key(settings, campaign_key, variation_id)
    campaign = settings.get_campaigns.find { |c| c.get_key == campaign_key }
    return nil unless campaign

    variation = campaign.get_variations.find { |v| v.get_id == variation_id }
    variation ? VariationModel.new.model_from_dictionary(variation) : nil
  end

  # Sets campaign allocation ranges
  # @param campaigns [Array<CampaignModel>] The campaigns to set the allocation ranges for
  def self.set_campaign_allocation(campaigns)
    current_allocation = 0

    campaigns.each do |campaign|
      step_factor = assign_range_values_meg(campaign, current_allocation)
      current_allocation += step_factor
    end
  end

  # Retrieves campaign group details if part of a group
  # @param settings [SettingsModel] The settings for the VWO instance
  # @param campaign_id [Integer] The ID of the campaign
  # @param variation_id [Integer] The ID of the variation
  # @return [Hash] The group details
  def self.get_group_details_if_campaign_part_of_it(settings, campaign_id, variation_id = nil)
    campaign_to_check = variation_id ? "#{campaign_id}_#{variation_id}" : campaign_id.to_s

    if settings.get_campaign_groups.key?(campaign_to_check)
      group_id = settings.get_campaign_groups[campaign_to_check]
      { group_id: group_id, group_name: settings.get_groups[group_id.to_s][:name.to_s]}
    else
      {}
    end
  end

  # Finds groups associated with a feature
  # @param settings [SettingsModel] The settings for the VWO instance
  # @param feature_key [String] The key of the feature
  # @return [Array] The groups associated with the feature
  def self.find_groups_feature_part_of(settings, feature_key)
    rule_array = []
    settings.get_features.each do |feature|
      if feature.get_key == feature_key
        rule_array.concat(feature.get_rules)
      end
    end

    groups = []
    rule_array.each do |rule|
      group = get_group_details_if_campaign_part_of_it(settings, rule.get_campaign_id, rule.get_type == CampaignTypeEnum::PERSONALIZE ? rule.get_variation_id : nil)
      groups << group unless group.empty? || groups.any? { |g| g[:group_id] == group[:group_id] }
    end

    groups
  end

  # Retrieves campaigns by group ID
  # @param settings [SettingsModel] The settings for the VWO instance
  # @param group_id [String] The ID of the group
  # @return [Array] The campaigns associated with the group
  def self.get_campaigns_by_group_id(settings, group_id)
    settings.get_groups[group_id.to_s]&.fetch(:campaigns.to_s, []) || []
  end

  # Retrieves feature keys from campaign IDs
  # @param settings [SettingsModel] The settings for the VWO instance
  # @param campaign_ids [Array] The IDs of the campaigns
  # @return [Array] The feature keys associated with the campaigns
  def self.get_feature_keys_from_campaign_ids(settings, campaign_ids)
    feature_keys = []

    campaign_ids.each do |campaign|
      campaign_id, variation_id = campaign.split('_').map(&:to_i)

      settings.get_features.each do |feature|
        next if feature_keys.include?(feature.get_key)

        feature.get_rules.each do |rule|
          if rule.get_campaign_id == campaign_id
            feature_keys << feature.get_key if variation_id.nil? || rule.get_variation_id == variation_id
          end
        end
      end
    end

    feature_keys
  end

  # Retrieves campaign IDs from a feature key
  # @param settings [SettingsModel] The settings for the VWO instance
  # @param feature_key [String] The key of the feature
  # @return [Array] The campaign IDs associated with the feature
  def self.get_campaign_ids_from_feature_key(settings, feature_key)
    settings.get_features.each do |feature|
      return feature.get_rules.map(&:get_campaign_id) if feature.get_key == feature_key
    end
    []
  end

  # Assigns range values to a MEG campaign
  # @param data [VariationModel] The variation to assign the start and end range values to
  # @param current_allocation [Integer] The current allocation
  # @return [Integer] The step factor
  def self.assign_range_values_meg(data, current_allocation)
    step_factor = get_variation_bucket_range(data.weight)

    if step_factor > 0
      data.start_range_variation = current_allocation + 1
      data.end_range_variation = current_allocation + step_factor
    else
      data.start_range_variation = -1
      data.end_range_variation = -1
    end

    step_factor
  end

  # Retrieves the rule type for a given campaign ID from a feature
  def self.get_rule_type_using_campaign_id_from_feature(feature, campaign_id)
    rule = feature.get_rules.find { |r| r.get_campaign_id == campaign_id }
    rule ? rule.get_type : ''
  end

  # Calculates bucket range for a variation
  # @param variation_weight [Float] The weight of the variation
  # @return [Integer] The bucket range
  def self.get_variation_bucket_range(variation_weight)
    return 0 unless variation_weight && variation_weight.positive?

    start_range = (variation_weight * 100).ceil
    [start_range, Constants::MAX_TRAFFIC_VALUE].min
  end

  # Handles rollout campaign logic
  # @param campaign [CampaignModel] The campaign to handle the rollout logic for
  def self.handle_rollout_campaign(campaign)
    campaign.get_variations.each do |variation|
      end_range = variation.get_weight * 100
      variation.set_start_range(1)
      variation.set_end_range(end_range)

      LoggerService.log(LogLevelEnum::INFO, "VARIATION_RANGE_ALLOCATION", {
        variationKey: variation.get_key,
        campaignKey: campaign.get_key,
        variationWeight: variation.get_weight,
        startRange: 1,
        endRange: end_range
      })
    end
  end

  # Retrieves the campaign key from the campaign ID
  # @param settings [SettingsModel] The settings for the VWO instance
  # @param campaign_id [Integer] The ID of the campaign
  # @return [String] The campaign key
  def self.get_campaign_key_from_campaign_id(settings, campaign_id)
    settings.get_campaigns.each do |campaign|
      return campaign.get_key if campaign.get_id == campaign_id
    end
    nil
  end

  # Retrieves the variation name from the campaign ID and variation ID
  # @param settings [SettingsModel] The settings for the VWO instance
  # @param campaign_id [Integer] The ID of the campaign
  # @param variation_id [Integer] The ID of the variation
  # @return [String] The variation name
  def self.get_variation_name_from_campaign_id_and_variation_id(settings, campaign_id, variation_id)
    campaign = settings.get_campaigns.find { |c| c.get_id == campaign_id }
    return nil unless campaign

    variation = campaign.get_variations.find { |v| v.get_id == variation_id }
    variation ? variation.get_key : nil
  end

  # Retrieves the campaign type from the campaign ID
  # @param settings [SettingsModel] The settings for the VWO instance
  # @param campaign_id [Integer] The ID of the campaign
  # @return [String] The campaign type
  def self.get_campaign_type_from_campaign_id(settings, campaign_id)
    campaign = settings.get_campaigns.find { |c| c.get_id == campaign_id }
    return nil unless campaign

    campaign.get_type
  end
end
