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

require_relative '../models/user/context_model'
require_relative '../enums/event_enum'
require_relative '../utils/network_util'
require_relative '../models/settings/settings_model'
require_relative '../services/batch_event_queue'

class SetAttributeApi
  # Sets multiple attributes for a user in a single network call.
  # @param settings [SettingsModel] Configuration settings.
  # @param attributes [Hash] Key-value map of attributes.
  # @param context [ContextModel] Context containing user information.
  def set_attribute(settings, attributes, context)
    create_impression_for_attributes(settings, attributes, context)
  end

  private

  # Creates an impression for multiple user attributes and sends it to the server.
  # @param settings [SettingsModel] Configuration settings.
  # @param attributes [Hash] Key-value map of attributes.
  # @param context [ContextModel] Context containing user information.
  def create_impression_for_attributes(settings, attributes, context)
    # Retrieve base properties for the event
    properties = NetworkUtil.get_events_base_properties(
      settings,
      EventEnum::VWO_SYNC_VISITOR_PROP,
      URI.encode_www_form_component(context.user_agent),
      context.ip_address
    )

    # Construct payload data for multiple attributes
    payload = NetworkUtil.get_attribute_payload_data(
      settings,
      context.id,
      EventEnum::VWO_SYNC_VISITOR_PROP,
      attributes,
      context.user_agent,
      context.ip_address
    )

    # check if batching is enabled
    if BatchEventsQueue.instance
      # add the payload to the batch events queue
      BatchEventsQueue.instance.enqueue(payload)
    else
      # Send the constructed payload via POST request
      NetworkUtil.send_post_api_request(properties, payload)
    end
  end
end
