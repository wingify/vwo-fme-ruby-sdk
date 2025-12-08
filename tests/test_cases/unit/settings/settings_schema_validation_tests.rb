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

require 'minitest/autorun'
require 'json'
require_relative '../../../../lib/vwo/services/settings_service'
require_relative '../../../../lib/vwo/models/schemas/settings_schema_validation'

class SettingsSchemaValidationTest < Minitest::Test
  def setup
    @settings_schema_validation = SettingsSchema.new
    @settings_service = SettingsService.new({
      account_id: 123,
      sdk_key: '123'
    })
  end

  def test_settings_with_wrong_type_for_values_should_fail_validation
    settings_data = load_settings_file('SETTINGS_WITH_WRONG_TYPE_FOR_VALUES')
    result = @settings_schema_validation.is_settings_valid(settings_data)
    assert_equal false, result
  end

  def test_settings_with_extra_key_at_root_level_should_not_fail_validation
    settings_data = load_settings_file('SETTINGS_WITH_EXTRA_KEYS_AT_ROOT_LEVEL')
    result = @settings_schema_validation.is_settings_valid(settings_data)
    assert_equal true, result
  end

  def test_settings_with_extra_key_inside_objects_should_not_fail_validation
    settings_data = load_settings_file('SETTINGS_WITH_EXTRA_KEYS_INSIDE_OBJECTS')
    result = @settings_schema_validation.is_settings_valid(settings_data)
    assert_equal true, result
  end

  def test_settings_with_no_feature_and_campaign_should_not_fail_validation
    settings_data = load_settings_file('SETTINGS_WITH_NO_FEATURES_AND_CAMPAIGNS')
    # The Ruby version doesn't have normalize_settings method, so we test the raw settings
    normalized_settings = SettingsService.normalize_settings(settings_data)
    result = @settings_schema_validation.is_settings_valid(normalized_settings)
    assert_equal true, result
  end

  private

  def load_settings_file(filename)
    file_path = File.join(__dir__, '../../../data/settings', "#{filename}.json")
    JSON.parse(File.read(file_path))
  end
end
