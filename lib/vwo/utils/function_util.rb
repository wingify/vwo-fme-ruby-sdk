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
require_relative '../models/campaign/campaign_model'
require_relative '../models/campaign/feature_model'
require_relative '../models/settings/settings_model'
require_relative '../utils/data_type_util'
require_relative '../services/logger_service'
require_relative '../enums/log_level_enum'
require_relative '../constants/constants'
require_relative '../utils/data_type_util'

# Clones an object deeply.
# @param obj [Object] The object to clone.
# @return [Object] The cloned object.
def clone_object(obj)
  return obj unless obj
  Marshal.load(Marshal.dump(obj))
end

# Gets the current time in ISO string format.
# @return [String] The current time in ISO string format.
def get_current_time
  Time.now.utc.iso8601
end

# Gets the current Unix timestamp in seconds.
# @return [Integer] The current Unix timestamp.
def get_current_unix_timestamp
  Time.now.to_i
end

# Gets the current Unix timestamp in milliseconds.
# @return [Integer] The current Unix timestamp in milliseconds.
def get_current_unix_timestamp_in_millis
  (Time.now.to_f * 1000).to_i
end

# Generates a random number between 0 and 1.
# @return [Float] A random number.
def get_random_number
  rand
end

# Retrieves specific rules based on the type from a feature.
# @param feature [FeatureModel] The feature object.
# @param type [CampaignTypeEnum, nil] The type of the rules to retrieve.
# @return [Array] An array of rules that match the type.
def get_specific_rules_based_on_type(feature, type = nil)
  return [] unless feature&.get_rules_linked_campaign

  return feature.get_rules_linked_campaign if type.nil? || !DataTypeUtil.is_string(type)

  feature.get_rules_linked_campaign.select do |rule|
    rule_model = CampaignModel.new.model_from_dictionary(rule)
    rule_model.get_type == type
  end
end

# Retrieves all AB and Personalize rules from a feature.
# @param feature [FeatureModel] The feature object.
# @return [Array] An array of AB and Personalize rules.
def get_all_experiment_rules(feature)
  return [] unless feature

  feature.get_rules_linked_campaign.select do |rule|
    [CampaignTypeEnum::AB, CampaignTypeEnum::PERSONALIZE].include?(rule.get_type)
  end
end

# Retrieves a feature by its key from the settings.
# @param settings [SettingsModel] The settings containing features.
# @param feature_key [String] The key of the feature to find.
# @return [FeatureModel, nil] The feature if found, otherwise nil.
def get_feature_from_key(settings, feature_key)
  return nil unless settings&.get_features

  settings.get_features.find { |feature| feature.get_key == feature_key }
end

# Checks if an event exists within any feature's metrics.
# @param event_name [String] The name of the event to check.
# @param settings [SettingsModel] The settings containing features.
# @return [Boolean] True if the event exists, otherwise false.
def does_event_belong_to_any_feature(event_name, settings)
  settings.get_features.any? do |feature|
    feature.get_metrics.any? { |metric| metric.get_identifier == event_name }
  end
end

# Adds linked campaigns to each feature in the settings based on rules.
# @param settings [SettingsModel] The settings file to modify.
def add_linked_campaigns_to_settings(settings)
  campaign_map = settings.get_campaigns.each_with_object({}) do |campaign, map|
    map[campaign.get_id] = campaign
  end

  settings.get_features.each do |feature|
    rules_linked_campaign = feature.get_rules.map do |rule|
      campaign = campaign_map[rule.get_campaign_id]
      next unless campaign

      linked_campaign = campaign.clone
      linked_campaign.set_rule_key(rule.get_rule_key)
      if rule.get_variation_id
        variation = campaign.get_variations.find { |v| v.get_id == rule.get_variation_id }
        linked_campaign.set_variations([variation]) if variation
      end

      linked_campaign
    end.compact

    feature.set_rules_linked_campaign(rules_linked_campaign)
  end
end
