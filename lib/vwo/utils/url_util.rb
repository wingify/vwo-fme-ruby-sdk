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

require_relative '../services/settings_service'

class UrlUtil
  @collection_prefix = nil

  class << self
    attr_accessor :collection_prefix

    # Initializes the UrlUtil with an optional collection prefix.
    #
    # @param collection_prefix [String] Optional prefix for URL collections.
    # @return [UrlUtil] The singleton instance of UrlUtil with updated properties.
    def init(collection_prefix: nil)
      @collection_prefix = collection_prefix if collection_prefix.is_a?(String)
      self
    end

    # Retrieves the base URL.
    #
    # @return [String] The base URL.
    def get_base_url
      base_url = SettingsService.instance.hostname

      return base_url if SettingsService.instance.is_gateway_service_provided

      # Construct URL with collection_prefix if it exists
      return "#{base_url}/#{@collection_prefix}" if @collection_prefix

      base_url
    end
  end
end
