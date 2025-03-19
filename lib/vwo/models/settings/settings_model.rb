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

require_relative '../campaign/campaign_model'
require_relative '../campaign/feature_model'

class SettingsModel
  attr_reader :sdk_key, :account_id, :version, :collection_prefix,
              :features, :campaigns, :campaign_groups, :groups

  def initialize(settings)
    @sdk_key = settings["sdkKey"]
    @account_id = settings["accountId"]
    @version = settings["version"]
    @collection_prefix = settings["collectionPrefix"]
    @features = []
    @campaigns = []
    @campaign_groups = settings["campaignGroups"] || {}
    @groups = settings["groups"] || {}

    process_features(settings)
    process_campaigns(settings)
  end

  def get_campaigns
    @campaigns
  end

  def get_features
    @features
  end

  def get_campaign_groups
    @campaign_groups
  end

  def get_groups
    @groups
  end

  def get_sdk_key
    @sdk_key
  end

  def get_account_id
    @account_id
  end

  def get_version
    @version
  end

  def get_collection_prefix
    @collection_prefix
  end

  def process_features(settings)
    feature_list = settings["features"]
    return unless feature_list.is_a?(Array)

    feature_list.each do |feature|
      @features << FeatureModel.new.model_from_dictionary(feature)
    end
  end

  def process_campaigns(settings)
    campaign_list = settings["campaigns"]
    return unless campaign_list.is_a?(Array)

    campaign_list.each do |campaign|
      @campaigns << CampaignModel.new.model_from_dictionary(campaign)
    end
  end
end
