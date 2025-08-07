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

require_relative './network_util'
require_relative '../enums/event_enum'
require_relative '../services/batch_event_queue'

# Sends an init called event to VWO.
# This event is triggered when the init function is called.
# @param settings_fetch_time [Number] Time taken to fetch settings in milliseconds.
# @param sdk_init_time [Number] Time taken to initialize the SDK in milliseconds.
def send_sdk_init_event(settings_fetch_time, sdk_init_time)
  # Get base properties for the event
  properties = NetworkUtil.get_events_base_properties(EventEnum::VWO_INIT_CALLED)
  payload = NetworkUtil.get_sdk_init_event_payload(EventEnum::VWO_INIT_CALLED, settings_fetch_time, sdk_init_time)

  # check if batching is enabled
  if BatchEventsQueue.instance
    # add the payload to the batch events queue
    BatchEventsQueue.instance.enqueue(payload)
  else
    # Send the constructed payload via POST request
    NetworkUtil.send_event(properties, payload)
  end
end