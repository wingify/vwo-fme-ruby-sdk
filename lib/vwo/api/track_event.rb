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
require_relative '../models/settings/settings_model'
require_relative '../models/user/context_model'
require_relative '../services/hooks_service'
require_relative '../utils/function_util'
require_relative '../utils/network_util'
require_relative '../services/logger_service'
require_relative '../services/batch_event_queue'

class TrackApi
  # Tracks an event with given properties and context.
  # @param settings [SettingsModel] Configuration settings.
  # @param event_name [String] Name of the event to track.
  # @param context [ContextModel] Contextual information like user details.
  # @param event_properties [Hash] Properties associated with the event.
  # @param hooks_service [HooksService] Manager for handling hooks and callbacks.
  # @return [Hash] A hash indicating success or failure of event tracking.
  def track(settings, event_name, context, event_properties, hooks_service)
    if does_event_belong_to_any_feature(event_name, settings)
      # Create an impression for the track event
      create_impression_for_track(event_name, context, event_properties)

      # Set and execute integration callback for the track event
      hooks_service.set({ event_name: event_name, api: ApiEnum::TRACK })
      hooks_service.execute(hooks_service.get)

      return { event_name: true }
    end

    # Log an error if the event does not exist
    LoggerService.log(LogLevelEnum::ERROR, "EVENT_NOT_FOUND", { eventName: event_name })

    { event_name: false }
  end

  private

  # Creates an impression for a track event and sends it via a POST API request.
  # @param event_name [String] Name of the event to track.
  # @param context [ContextModel] User details.
  # @param event_properties [Hash] Properties associated with the event.
  def create_impression_for_track(event_name, context, event_properties)
    # Get base properties for the event
    properties = NetworkUtil.get_events_base_properties(
      event_name,
      URI.encode_www_form_component(context.user_agent),
      context.ip_address
    )

    # Prepare the payload for the track goal
    payload = NetworkUtil.get_track_goal_payload_data(
      context.id,
      event_name,
      event_properties,
      context.user_agent,
      context.ip_address
    )

    # check if batching is enabled
    if BatchEventsQueue.instance
      # add the payload to the batch events queue
      BatchEventsQueue.instance.enqueue(payload)
    else
      # Send the prepared payload via POST API request
      NetworkUtil.send_post_api_request(properties, payload)
    end
  end
end
