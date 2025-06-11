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

require_relative '../enums/api_enum'
require_relative '../enums/campaign_type_enum'
require_relative '../enums/decision_types_enum'
require_relative '../decorators/storage_decorator'
require_relative '../services/storage_service'
require_relative '../models/campaign/feature_model'
require_relative '../models/campaign/campaign_model'
require_relative '../packages/segmentation_evaluator/core/segmentation_manager'
require_relative '../services/logger_service'
require_relative '../utils/campaign_util'
require_relative '../utils/rule_evaluation_util'
require_relative '../utils/impression_util'
require_relative '../utils/decision_util'
require_relative '../models/user/get_flag_response'
require_relative '../packages/storage/storage'

class FlagApi
    # Get the flag for a given feature key and context
    # @param feature_key [String] The key of the feature to get the flag for
    # @param settings [SettingsModel] The settings for the VWO instance
    # @param context [ContextModel] The context for the evaluation
    # @param hooks_service [HooksService] The hooks service for the VWO instance
    # @return [GetFlagResponse] The flag for the given feature key and context
    def get(feature_key, settings, context, hooks_service)
      is_enabled = false
      rollout_variation_to_return = nil
      experiment_variation_to_return = nil
      should_check_for_experiments_rules = false
  
      passed_rules_information = {} # for storing integration callback
      evaluated_feature_map = {}

      # Fetch feature object using the feature key
      feature = get_feature_from_key(settings, feature_key)
  
      decision = {
        feature_name: feature&.get_name,
        feature_id: feature&.get_id,
        feature_key: feature&.get_key,
        user_id: context&.get_id,
        api: ApiEnum::GET_FLAG
      }
  
      storage_service = StorageService.new
      if Storage.instance.is_storage_enabled
        stored_data = StorageDecorator.new.get_feature_from_storage(feature_key, context, storage_service)
    
        if stored_data && stored_data[:experiment_variation_id]
          if stored_data[:experiment_key]
            variation = CampaignUtil.get_variation_from_campaign_key(settings, stored_data[:experiment_key], stored_data[:experiment_variation_id])
    
            if variation
              LoggerService.log(LogLevelEnum::INFO, "STORED_VARIATION_FOUND", {variationKey: variation.get_key, userId: context.get_id, experimentKey: stored_data[:experiment_key], experimentType: "experiment"})
              return GetFlagResponse.new(true, variation.get_variables)
            end
          end
        elsif stored_data && stored_data[:rollout_key] && stored_data[:rollout_id]
          variation = CampaignUtil.get_variation_from_campaign_key(settings, stored_data[:rollout_key], stored_data[:rollout_variation_id])
    
          if variation
            LoggerService.log(LogLevelEnum::INFO, "STORED_VARIATION_FOUND", {variationKey: variation.get_key, userId: context.get_id, experimentKey: stored_data[:rollout_key], experimentType: "rollout"})
            LoggerService.log(LogLevelEnum::DEBUG, "EXPERIMENTS_EVALUATION_WHEN_ROLLOUT_PASSED", {userId: context.get_id})
    
            is_enabled = true
            should_check_for_experiments_rules = true
            rollout_variation_to_return = variation
            feature_info = {
              rollout_id: stored_data[:rollout_id],
              rollout_key: stored_data[:rollout_key],
              rollout_variation_id: stored_data[:rollout_variation_id]
            }
            evaluated_feature_map[feature_key] = feature_info
            passed_rules_information.merge!(feature_info)
          end
        end
      end
  
      if feature.nil?
        LoggerService.log(LogLevelEnum::ERROR, "FEATURE_NOT_FOUND", {featureKey: feature_key})
        return GetFlagResponse.new(false, [])
      end
  
      # Segmentation evaluation
      SegmentationManager.instance.set_contextual_data(settings, feature, context)
  
      # Get all rollout rules
      rollout_rules = get_specific_rules_based_on_type(feature, CampaignTypeEnum::ROLLOUT)
  
      if rollout_rules.any? && !is_enabled
        rollout_rules_to_evaluate = []
  
        rollout_rules.each do |rule|
          result = evaluate_rule(settings, feature, rule, context, evaluated_feature_map, nil, storage_service, decision)
          pre_segmentation_result = result[:pre_segmentation_result]
          updated_decision = result[:updated_decision]
          decision.merge!(updated_decision) if updated_decision
  
          if pre_segmentation_result
            rollout_rules_to_evaluate << rule
            evaluated_feature_map[feature_key] = {
              rollout_id: rule.get_id,
              rollout_key: rule.get_key,
              rollout_variation_id: rule.get_variations.first&.get_id
            }
            break
          end
        end
  
        if rollout_rules_to_evaluate.any?
          passed_rollout_campaign = CampaignModel.new.model_from_dictionary(rollout_rules_to_evaluate.first)
          variation = DecisionUtil.evaluate_traffic_and_get_variation(settings, passed_rollout_campaign, context.get_id)
  
          if variation
            is_enabled = true
            should_check_for_experiments_rules = true
            rollout_variation_to_return = variation
            update_integrations_decision_object(passed_rollout_campaign, variation, passed_rules_information, decision)
  
            create_and_send_impression_for_variation_shown(settings, passed_rollout_campaign.get_id, variation.get_id, context)
          end
        end
      elsif rollout_rules.empty?
        LoggerService.log(LogLevelEnum::DEBUG, "EXPERIMENTS_EVALUATION_WHEN_NO_ROLLOUT_PRESENT")
        should_check_for_experiments_rules = true
      end
  
      if should_check_for_experiments_rules
        experiment_rules = get_all_experiment_rules(feature)
        experiment_rules_to_evaluate = []
        meg_group_winner_campaigns = {}
  
        experiment_rules.each do |rule|
          result = evaluate_rule(settings, feature, rule, context, evaluated_feature_map, meg_group_winner_campaigns, storage_service, decision)
          pre_segmentation_result = result[:pre_segmentation_result]
          whitelisted_object = result[:whitelisted_object]
          updated_decision = result[:updated_decision]
          decision.merge!(updated_decision) if updated_decision

          if pre_segmentation_result
            if whitelisted_object.nil?
              experiment_rules_to_evaluate << rule
            else
              is_enabled = true
              experiment_variation_to_return = whitelisted_object[:variation]
              passed_rules_information.merge!(
                experiment_id: rule.get_id,
                experiment_key: rule.get_key,
                experiment_variation_id: whitelisted_object[:variation_id]
              )
            end
            break
          end
        end
  
        if experiment_rules_to_evaluate.any?
          campaign = CampaignModel.new.model_from_dictionary(experiment_rules_to_evaluate.first)
          variation = DecisionUtil.evaluate_traffic_and_get_variation(settings, campaign, context.get_id)
  
          if variation
            is_enabled = true
            experiment_variation_to_return = variation
            update_integrations_decision_object(campaign, variation, passed_rules_information, decision)
  
            create_and_send_impression_for_variation_shown(settings, campaign.get_id, variation.get_id, context)
          end
        end
      end
  
      # Store evaluated feature in storage
      if is_enabled
        StorageDecorator.new.set_data_in_storage(
          { feature_key: feature_key, context: context }.merge(passed_rules_information),
          storage_service
        )
      end
  
      # Execute hooks
      hooks_service.set(decision)
      hooks_service.execute(hooks_service.get)

      if feature&.get_impact_campaign&.get_campaign_id
        LoggerService.log(
          LogLevelEnum::INFO,
          "IMPACT_ANALYSIS",
          {
            userId: context.get_id,
            featureKey: feature_key,
            status: is_enabled ? 'enabled' : 'disabled'
          }
        )
      
        variation_id = is_enabled ? 2 : 1 # 2 for Variation(flag enabled), 1 for Control(flag disabled)
        
        create_and_send_impression_for_variation_shown(
          settings,
          feature&.get_impact_campaign&.get_campaign_id,
          variation_id,
          context
        )
      end
  
      # Return final evaluated feature flag
      return GetFlagResponse.new(is_enabled, experiment_variation_to_return&.get_variables || rollout_variation_to_return&.get_variables || [])
    end
  
    private
  
    def update_integrations_decision_object(campaign, variation, passed_rules_information, decision)
      if campaign.get_type == CampaignTypeEnum::ROLLOUT
        passed_rules_information.merge!(
          rollout_id: campaign.get_id,
          rollout_key: campaign.get_key,
          rollout_variation_id: variation.get_id
        )
      else
        passed_rules_information.merge!(
          experiment_id: campaign.get_id,
          experiment_key: campaign.get_key,
          experiment_variation_id: variation.get_id
        )
      end
      decision.merge!(passed_rules_information)
    end
  end
  