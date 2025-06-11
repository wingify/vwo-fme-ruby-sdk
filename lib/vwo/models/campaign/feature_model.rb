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

require_relative 'campaign_model'
require_relative 'impact_campaign_model'
require_relative 'metric_model'
require_relative 'rule_model'

class FeatureModel
  attr_reader :id, :key, :name, :type, :rules, :impact_campaign, :rules_linked_campaign, :metrics, :is_gateway_service_required

  def initialize
    @id = nil
    @key = ''
    @name = ''
    @type = ''
    @rules = []
    @impact_campaign = nil
    @rules_linked_campaign = []
    @metrics = []
    @is_gateway_service_required = false
  end

  # Creates a model instance from a hash (dictionary)
  def model_from_dictionary(feature)
    @id = feature["id"]
    @key = feature["key"]
    @name = feature["name"]
    @type = feature["type"]
    @is_gateway_service_required = feature["is_gateway_service_required"] if feature.key?("is_gateway_service_required")

    if feature["impactCampaign"]
      @impact_campaign = ImpactCampaignModel.new.model_from_dictionary(feature["impactCampaign"])
    end

    @metrics = process_metrics(feature["metrics"])
    @rules = process_rules(feature["rules"])
    @rules_linked_campaign = feature["rules_linked_campaign"].is_a?(Array) ? feature["rules_linked_campaign"] : []

    self
  end

  # Setter method for rules_linked_campaign
  def set_rules_linked_campaign(rules_linked_campaign)
    @rules_linked_campaign = rules_linked_campaign
  end

  # Setter method for is_gateway_service_required
  def set_is_gateway_service_required(is_gateway_service_required)
    @is_gateway_service_required = is_gateway_service_required
  end

  def get_id
    @id
  end

  def get_key
    @key
  end

  def get_name
    @name
  end

  def get_type
    @type
  end

  def get_rules
    @rules
  end

  def get_impact_campaign
    @impact_campaign
  end

  def get_rules_linked_campaign
    @rules_linked_campaign
  end

  def get_metrics
    @metrics
  end

  def get_is_gateway_service_required
    @is_gateway_service_required
  end

  # Process rules list
  def process_rules(rule_list)
    return [] unless rule_list.is_a?(Array)
    rule_list.map { |rule| RuleModel.new.model_from_dictionary(rule) }
  end

  # Process metrics list
  def process_metrics(metric_list)
    return [] unless metric_list.is_a?(Array)
    metric_list.map { |metric| MetricModel.new.model_from_dictionary(metric) }
  end
end
