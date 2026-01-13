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

require_relative '../models/settings/settings_model'
require_relative './network_util'
require_relative '../models/user/context_model'
require_relative '../enums/event_enum'
require_relative '../services/batch_event_queue'
require_relative '../utils/campaign_util'
# Creates and sends an impression for a variation shown event.
# This function constructs the necessary properties and payload for the event
# and uses the NetworkUtil to send a POST API request.
#
# @param settings [SettingsModel] The settings model containing configuration.
# @param campaign_id [Integer] The ID of the campaign.
# @param variation_id [Integer] The ID of the variation shown to the user.
# @param context [ContextModel] The user context model containing user-specific data.
def create_and_send_impression_for_variation_shown(settings, campaign_id, variation_id, context, feature_key)
  # Get base properties for the event
  properties = NetworkUtil.get_events_base_properties(
    EventEnum::VWO_VARIATION_SHOWN,
    URI.encode_www_form_component(context.get_user_agent), # Encode user agent for URL safety
    context.get_ip_address
  )

  # Construct payload data for tracking the user
  payload = NetworkUtil.get_track_user_payload_data(
    EventEnum::VWO_VARIATION_SHOWN,
    campaign_id,
    variation_id,
    context
  )

  campaign_key_with_feature_name = CampaignUtil.get_campaign_key_from_campaign_id(settings, campaign_id)
  variation_name = CampaignUtil.get_variation_name_from_campaign_id_and_variation_id(settings, campaign_id, variation_id)

  campaign_key = ''

  if feature_key == campaign_key_with_feature_name
    campaign_key = Constants::IMPACT_ANALYSIS
  else
    campaign_key = campaign_key_with_feature_name.split("#{feature_key}_")[1]
  end

  campaign_type = CampaignUtil.get_campaign_type_from_campaign_id(settings, campaign_id)

  # check if batching is enabled
  if BatchEventsQueue.instance
    # add the payload to the batch events queue
    BatchEventsQueue.instance.enqueue(payload)
  else
    # Send the constructed payload via POST request
    NetworkUtil.send_post_api_request(properties, payload, { campaign_type: campaign_type, feature_key: feature_key, campaign_key: campaign_key, variation_name: variation_name })
  end
end
