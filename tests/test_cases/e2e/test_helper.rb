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

require_relative '../../../lib/vwo/services/settings_service'
require 'test/unit'
$LOAD_PATH.unshift File.expand_path('../../../lib', __dir__)
$LOAD_PATH.unshift File.expand_path('../../data', __dir__)

# Stub SettingsService.new to always return your custom instance
def stub_settings_service_valid!(options = {})
    custom_settings_service = SettingsService.allocate
    custom_settings_service.send(:initialize, @options)
    custom_settings_service.instance_variable_set(:@is_settings_valid, true)

    # Stub SettingsService.new to always return your custom instance
    SettingsService.stubs(:new).returns(custom_settings_service)
end