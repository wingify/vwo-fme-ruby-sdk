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

require_relative '../services/logger_service'
require_relative '../enums/log_level_enum'
require_relative '../utils/network_util'
require_relative '../services/batch_event_queue'
require_relative '../enums/event_enum'

class DebuggerServiceUtil
  class << self
    def send_debugger_event(event_props)
      # get base properties for the event
      properties = NetworkUtil.get_events_base_properties(EventEnum::VWO_DEBUGGER_EVENT)

      # get debugger event payload
      payload = NetworkUtil.get_debugger_event_payload(event_props)

      # send event
      if BatchEventsQueue.instance
        # add the payload to the batch events queue
        BatchEventsQueue.instance.enqueue(payload)
      else
        # Send the prepared payload via POST API request
        NetworkUtil.send_event(properties, payload)
      end
    end
  end
end