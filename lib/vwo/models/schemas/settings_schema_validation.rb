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

require 'dry-schema'

class SettingsSchema
  def initialize
    initialize_schemas
  end

  def initialize_schemas
    @campaign_metric_schema = Dry::Schema.Params do
      required(:id).filled(:integer)
      required(:type).filled(:string)
      required(:identifier).filled(:string)
      optional(:mca).maybe(:integer)
      optional(:hasProps).maybe(:bool)
      optional(:revenueProp).maybe(:string)
    end

    @variable_object_schema = Dry::Schema.Params do
      required(:id).filled(:integer)
      required(:type).filled(:string)
      required(:key).filled(:string)
      required(:value).filled(:string) # Ensuring consistent type
    end

    @campaign_variation_schema = Dry::Schema.Params do
      required(:id).filled(:integer)
      required(:name).filled(:string)
      required(:weight).filled(:integer)
      optional(:segments).maybe(:hash)
      optional(:variables).array(:hash) # Ensuring it takes an array of hashes
      optional(:startRangeVariation).maybe(:integer)
      optional(:endRangeVariation).maybe(:integer)
      optional(:salt).maybe(:string)
    end

    @campaign_object_schema = Dry::Schema.Params do
      required(:id).filled(:integer)
      required(:type).filled(:string)
      required(:key).filled(:string)
      optional(:percentTraffic).maybe(:integer)
      required(:status).filled(:string)
      required(:variations).array(:hash) # Referencing schema using array of hashes
      required(:segments).filled(:hash)
      optional(:isForcedVariationEnabled).maybe(:bool)
      optional(:isAlwaysCheckSegment).maybe(:bool)
      required(:name).filled(:string)
      optional(:salt).maybe(:string)
    end

    @rule_schema = Dry::Schema.Params do
      required(:type).filled(:string)
      required(:ruleKey).filled(:string)
      required(:campaignId).filled(:integer)
      optional(:variationId).maybe(:integer)
    end

    @feature_schema = Dry::Schema.Params do
      required(:id).filled(:integer)
      required(:key).filled(:string)
      required(:status).filled(:string)
      required(:name).filled(:string)
      required(:type).filled(:string)
      required(:metrics).array(:hash)
      optional(:impactCampaign).maybe(:hash)
      optional(:rules).array(:hash)
      optional(:variables).array(:hash)
    end

    @settings_schema = Dry::Schema.Params do
      optional(:sdkKey).maybe(:string)
      required(:version).filled(:integer)
      required(:accountId).filled(:integer)
      optional(:features).array(:hash)
      required(:campaigns).array(:hash)
      optional(:groups).maybe(:hash)
      optional(:campaignGroups).maybe(:hash)
      optional(:collectionPrefix).maybe(:string)
      optional(:sdkMetaInfo).maybe(:hash)
    end
  end

  # Validate the settings model
  def is_settings_valid(settings)
    return false if settings.nil?

    result = @settings_schema.call(settings)
    result.errors.empty?
  end
end
