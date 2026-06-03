# Copyright 2024-2026 Wingify Software Pvt. Ltd.
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

require_relative '../constants/constants'

# BrandUtil provides pure, side-effect-free selectors for brand-specific constants.
# Every method takes an explicit is_via_vwo boolean so it can be used
# both at init time (reading BrandContext) and in tests (passed directly).
module BrandUtil
  # Returns the gem/SDK name sent in network requests.
  # Values: 'vwo-fme-ruby-sdk' or 'wingify-fme-ruby-sdk'
  def self.get_sdk_name(is_via_vwo)
    is_via_vwo ? Constants::VWO_SDK_NAME : Constants::WINGIFY_SDK_NAME
  end

  # Returns the hostname used to FETCH SETTINGS.
  # VWO:     dev.visualwebsiteoptimizer.com
  # Wingify: edge.wingify.net
  def self.get_settings_hostname(is_via_vwo)
    is_via_vwo ? Constants::VWO_HOST_NAME : Constants::WINGIFY_SETTINGS_HOST_NAME
  end

  # Returns the hostname used for ALL COLLECT / EVENT calls
  # (track user, track goal, set attribute, batch events, usage stats, debugger events, SDK init event).
  # VWO:     dev.visualwebsiteoptimizer.com
  # Wingify: collect.wingify.net
  def self.get_events_hostname(is_via_vwo)
    is_via_vwo ? Constants::VWO_HOST_NAME : Constants::WINGIFY_COLLECTION_HOST_NAME
  end

  # Returns the log prefix shown in every log line.
  # Values: 'VWO-SDK' or 'Wingify-SDK'
  def self.get_log_prefix(is_via_vwo)
    is_via_vwo ? Constants::VWO_LOG_PREFIX : Constants::WINGIFY_LOG_PREFIX
  end

  # Returns the human-readable brand display name used in messages.
  # Values: 'VWO' or 'Wingify'
  def self.get_brand_name(is_via_vwo)
    is_via_vwo ? Constants::VWO_BRAND_DISPLAY_NAME : Constants::WINGIFY_BRAND_DISPLAY_NAME
  end
end
