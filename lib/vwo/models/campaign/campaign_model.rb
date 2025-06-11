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

require_relative 'metric_model'
require_relative 'variable_model'
require_relative 'variation_model'

class CampaignModel
  attr_reader :id, :segments, :salt, :percent_traffic, :is_user_list_enabled, :key, :type, :name,
              :is_forced_variation_enabled, :variations, :metrics, :variables, :variation_id,
              :campaign_id, :rule_key

  def initialize
    @id = nil
    @segments = {}
    @salt = ''
    @percent_traffic = 0
    @is_user_list_enabled = false
    @key = ''
    @type = ''
    @name = ''
    @is_forced_variation_enabled = false
    @variations = []
    @metrics = []
    @variables = []
    @variation_id = nil
    @campaign_id = nil
    @rule_key = ''
  end

  # Copies campaign properties from another CampaignModel instance
  def copy(campaign_model)
    @metrics = campaign_model.metrics
    @variations = campaign_model.variations
    @variables = campaign_model.variables
    process_campaign_keys(campaign_model)
  end

  # Creates a model instance from a dictionary (hash) or CampaignModel
  def model_from_dictionary(campaign)
    if campaign.is_a?(Hash)
      process_campaign_properties(campaign)
      process_campaign_keys(campaign)
    elsif campaign.is_a?(CampaignModel)
      process_campaign_model(campaign)
    end
    self
  end

  def get_id
    @id
  end

  def get_segments
    @segments
  end

  def get_salt
    @salt
  end

  def get_traffic
    @percent_traffic
  end

  def get_is_user_list_enabled
    @is_user_list_enabled
  end

  def get_key
    @key
  end

  def set_key(key)
    @key = key
  end

  def get_type
    @type
  end
  
  def get_name
    @name
  end

  def get_is_forced_variation_enabled
    @is_forced_variation_enabled
  end

  def get_variations
    @variations
  end

  def set_variations(variations)
    @variations = variations
  end

  def get_metrics
    @metrics
  end

  def get_variables
    @variables
  end

  def get_variation_id
    @variation_id
  end

  def get_campaign_id
    @campaign_id
  end

  def get_rule_key
    @rule_key
  end

  def set_rule_key(rule_key)
    @rule_key = rule_key
  end

  # Process campaign properties (metrics, variations, variables)
  def process_campaign_properties(campaign)
    @variables = process_variables(campaign["variables"]) if campaign["variables"]
    @variations = process_variations(campaign["variations"]) if campaign["variations"]
    @metrics = process_metrics(campaign["metrics"]) if campaign["metrics"]
  end

  # Process campaign keys
  def process_campaign_keys(campaign)
    @id = campaign["id"]
    @percent_traffic = campaign["percentTraffic"]
    @name = campaign["name"]
    @variation_id = campaign["variationId"]
    @campaign_id = campaign["campaignId"]
    @rule_key = campaign["ruleKey"]
    @is_forced_variation_enabled = campaign["isForcedVariationEnabled"]
    @is_user_list_enabled = campaign["isUserListEnabled"]
    @segments = campaign["segments"]
    @key = campaign["key"]
    @type = campaign["type"]
    @salt = campaign["salt"]
  end

  # Process variables
  def process_variables(variable_list)
    return [] if variable_list.nil? || variable_list.is_a?(Hash) # Handle empty cases
    variable_list.map { |variable| VariableModel.new.model_from_dictionary(variable) }
  end

  # Process variations
  def process_variations(variation_list)
    return [] if variation_list.nil? || variation_list.is_a?(Hash) # Handle empty cases
    variation_list.map { |variation| VariationModel.new.model_from_dictionary(variation) }
  end

  # Process metrics
  def process_metrics(metrics_list)
    return [] if metrics_list.nil? || metrics_list.is_a?(Hash) # Handle empty cases
    metrics_list.map { |metric| MetricModel.new.model_from_dictionary(metric) }
  end

  # Process campaign properties from CampaignModel instance
  def process_campaign_model(campaign_model)
    @variables = campaign_model.variables
    @variations = campaign_model.variations
    @metrics = campaign_model.metrics
    @id = campaign_model.id
    @percent_traffic = campaign_model.percent_traffic
    @name = campaign_model.name
    @variation_id = campaign_model.variation_id
    @campaign_id = campaign_model.campaign_id
    @rule_key = campaign_model.rule_key
    @is_forced_variation_enabled = campaign_model.is_forced_variation_enabled
    @is_user_list_enabled = campaign_model.is_user_list_enabled
    @segments = campaign_model.segments
    @key = campaign_model.key
    @type = campaign_model.type
    @salt = campaign_model.salt
  end
end
