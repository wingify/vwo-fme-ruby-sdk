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

require_relative '../models/settings/settings_model'
require_relative 'campaign_util'
require_relative 'function_util'
require_relative 'gateway_service_util'

# Sets settings and adds campaigns to rules
#
# @param settings [Hash] The settings configuration
# @param vwo_client_instance [VWOClient] The VWOClient instance
def set_settings_and_add_campaigns_to_rules(settings, vwo_client_instance)
  # Create settings model and assign it to vwo_client_instance
  vwo_client_instance.settings = SettingsModel.new(settings)
  vwo_client_instance.original_settings = settings

  # Optimize loop by avoiding multiple calls to get_campaigns()
  campaigns = vwo_client_instance.settings.get_campaigns
  campaigns.each_with_index do |campaign, index|
    CampaignUtil.set_variation_allocation(campaign)
    campaigns[index] = campaign
  end

  add_linked_campaigns_to_settings(vwo_client_instance.settings)
  add_is_gateway_service_required_flag(vwo_client_instance.settings)
end
