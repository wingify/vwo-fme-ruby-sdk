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
require 'mocha/minitest'
require_relative '../../lib/vwo'
require_relative '../../lib/vwo/vwo_builder'
require_relative '../../lib/vwo/vwo_client'
require_relative '../../lib/vwo/services/logger_service'
require_relative '../data/storage_test'
require_relative '../data/dummy_settings_reader'
require_relative '../data/test_cases/test_cases'
require_relative '../data/test_data_reader'
require_relative '../../lib/vwo/packages/storage/storage'
require_relative 'test_helper'

class VWOClientTest < Minitest::Test
  def setup
    @settings_map = DummySettingsReader.new.settings_map
    @test_cases = TestDataReader.new.test_cases
  end

  def test_get_flag_without_storage
    run_tests(@test_cases["GETFLAG_WITHOUT_STORAGE"], false)
  end

  def test_get_flag_with_salt
    run_salt_test(@test_cases["GETFLAG_WITH_SALT"])
  end

  def test_get_flag_with_meg_random
    run_tests(@test_cases["GETFLAG_MEG_RANDOM"], false)
  end

  def test_get_flag_with_meg_advance
    run_tests(@test_cases["GETFLAG_MEG_ADVANCE"], false)
  end

  def test_get_flag_with_storage
    run_tests(@test_cases["GETFLAG_WITH_STORAGE"], true)
  end

  private

  def run_tests(tests, storage_map)
    tests.each do |test_data|
        storage = StorageTest.new
        threading = { enabled: false }
        stub_settings_service_valid!(@options)
        settings = JSON.parse(@settings_map[test_data['settings']])
        VWOBuilder.any_instance.stubs(:get_settings).returns(settings)
        @options = { sdk_key: 'test_sdk_key', account_id: 12345, threading: threading}
        if (storage_map)
            @options = { sdk_key: 'test_sdk_key', account_id: 12345, storage: storage, threading: threading}
        end
        Storage.instance.attach_connector(@options[:storage])
        @vwo_instance = VWO.init(@options)
        context = test_data['context'].transform_keys!(&:to_sym) if test_data['context'].is_a?(Hash)
        context[:customVariables] = context[:customVariables].transform_keys!(&:to_sym) if context[:customVariables].is_a?(Hash)

        if storage_map
            storage_data = storage.get(test_data['featureKey'], context[:id])
            assert_nil(storage_data)
        end

        feature_flag = @vwo_instance.get_flag(test_data['featureKey'], context)
        assert_equal(test_data['expectation']['isEnabled'], feature_flag.is_enabled)
        assert_equal(test_data['expectation']['intVariable'], feature_flag.get_variable('int', 1).to_f)
        assert_equal(test_data['expectation']['stringVariable'], feature_flag.get_variable('string', 'VWO'))
        assert_equal(test_data['expectation']['floatVariable'], feature_flag.get_variable('float', 1.1))
        assert_equal(test_data['expectation']['booleanVariable'], feature_flag.get_variable('boolean', false))
        assert_equal(test_data['expectation']['jsonVariable'], feature_flag.get_variable('json', {}))

        if storage_map && test_data['expectation']['isEnabled']
            updated_storage_data = storage.get(test_data['featureKey'], context[:id])
            stored_data = JSON.parse(updated_storage_data.to_json, symbolize_names: true)

            assert_equal test_data['expectation']['storageData']['rolloutKey'], stored_data[:rollout_key]
            assert_equal test_data['expectation']['storageData']['rolloutVariationId'], stored_data[:rollout_variation_id]
            assert_equal test_data['expectation']['storageData']['experimentKey'], stored_data[:experiment_key]
            assert_equal test_data['expectation']['storageData']['experimentVariationId'], stored_data[:experiment_variation_id]
        end
    end
  end

  def run_salt_test(tests)
    tests.each do |test_data|
      settings = JSON.parse(@settings_map[test_data['settings']])
      stub_settings_service_valid!(@options)
      VWOBuilder.any_instance.stubs(:get_settings).returns(settings)
      threading = { enabled: false }
      @options = {
        sdk_key: 'test_sdk_key',
        account_id: 12345,
        threading: threading
      }
      Storage.instance.attach_connector(@options[:storage])
      vwo_client = VWO.init(@options)

      test_data['userIds'].each do |user_id|
        vwo_context = { id: user_id }
        feature_flag = vwo_client.get_flag(test_data['featureKey'], vwo_context)
        feature_flag2 = vwo_client.get_flag(test_data['featureKey2'], vwo_context)

        feature_flag_variables = feature_flag.get_variables
        feature_flag2_variables = feature_flag2.get_variables

        feature_flag_variables_hash = feature_flag_variables.each_with_object({}) do |variable, hash|
            hash[variable.key] = variable.value
        end

        feature_flag2_variables_hash = feature_flag2_variables.each_with_object({}) do |variable, hash|
            hash[variable.key] = variable.value
        end

        if test_data['expectation']['shouldReturnSameVariation']
          assert_equal(feature_flag_variables_hash, feature_flag2_variables_hash)
        else
          refute_equal(feature_flag_variables_hash, feature_flag2_variables_hash)
        end
      end
    end
  end
end
