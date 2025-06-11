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
    settings = JSON.parse(@settings_map[@test_cases["GETFLAG_WITHOUT_STORAGE"][0]['settings']])
    VWOBuilder.any_instance.stubs(:get_settings).returns(settings)
    threading = { enabled: false }
    @options = { sdk_key: 'test_sdk_key', account_id: 12345, threading: threading}
    @vwo_instance = VWO.init(@options)
  end

  def test_should_track_event_successfully
    stub_settings_service_valid!(@options)
    puts "VWO instance initialized: #{@vwo_instance.nil? ? 'No' : 'Yes'}"
    event_name = 'custom1'
    event_properties = { key: 'value' }
    context = { id: '123' }

    result = @vwo_instance.track_event(event_name, context, event_properties)
    assert_equal({ event_name: true }, result)
  end

  def test_should_not_track_event_without_corresponding_metric
    event_name = 'testEvent'
    event_properties = { key: 'value' }
    context = { id: '123' }

    result = @vwo_instance.track_event(event_name, context, event_properties)
    assert_equal({ event_name: false }, result)
  end

  def test_should_handle_invalid_event_name
    event_name = 123 # Invalid event name
    event_properties = { key: 'value' }
    context = { id: '123' }

    result = @vwo_instance.track_event(event_name, context, event_properties)
    assert_equal({ event_name: false }, result)
  end

  def test_should_handle_invalid_event_properties
    event_name = 'testEvent'
    event_properties = 'invalid' # Invalid event properties
    context = { id: '123' }

    result = @vwo_instance.track_event(event_name, context, event_properties)
    assert_equal({ event_name: false }, result)
  end

  def test_should_handle_invalid_context
    event_name = 'testEvent'
    event_properties = { key: 'value' }
    context = {} # Invalid context without id

    result = @vwo_instance.track_event(event_name, context, event_properties)
    assert_equal({ event_name: false }, result)
  end
end
