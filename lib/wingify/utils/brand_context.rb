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

# BrandContext holds a single runtime flag that is set ONCE at init() time,
# before any service (Logger, SettingsService, etc.) is initialized.
# All brand-specific decisions (hostnames, SDK name, log prefix) read this flag.
module BrandContext
  @is_via_vwo = false

  class << self
    # Set the brand flag. Must be called as the very first step inside init().
    # @param val [Boolean] true = VWO brand, false = Wingify brand
    def set_is_via_vwo(val)
      @is_via_vwo = val == true
    end

    # @return [Boolean] true if the active brand is VWO
    def is_via_vwo?
      @is_via_vwo
    end
  end
end
