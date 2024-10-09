# Copyright 2024 Wingify Software Pvt. Ltd.
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

require_relative 'constants'
require_relative 'utils/request'  # Include your request utilities

module VWO
  class VWOBuilder
    def initialize(options)
      @options = options
    end

    # Initializes the HTTP client for VWOBuilder
    def init_client
      Utils::Request.set_base_url(@options[:gateway_service_url] || Constants::HTTPS_PROTOCOL + Constants::BASE_URL)
    end
  end
end
