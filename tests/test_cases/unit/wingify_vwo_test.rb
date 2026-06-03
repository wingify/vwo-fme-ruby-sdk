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

require_relative '../e2e/test_helper'
require_relative '../../../../lib/wingify/utils/brand_util'
require_relative '../../../../lib/wingify/utils/brand_context'
require_relative '../../../../lib/vwo'
require_relative '../../../../lib/wingify'

class RuntimeBrandTest < Minitest::Test
  #test is via vwo true -> brand selector -> vwo
  def test_vwo_runtime_brand
    BrandContext.set_is_via_vwo(true)
    assert_equal "vwo-fme-ruby-sdk", BrandUtil.get_sdk_name(true)
    assert_equal "dev.visualwebsiteoptimizer.com", BrandUtil.get_settings_hostname(true)
    assert_equal "dev.visualwebsiteoptimizer.com", BrandUtil.get_events_hostname(true)
    assert_equal "VWO-SDK", BrandUtil.get_log_prefix(true)
    assert_equal "VWO", BrandUtil.get_brand_name(true)
  end

  #test is via vwo false -> wingify
  def test_wingify_runtime_brand
    BrandContext.set_is_via_vwo(false)
    assert_equal "wingify-fme-ruby-sdk", BrandUtil.get_sdk_name(false)
    assert_equal "edge.wingify.net", BrandUtil.get_settings_hostname(false)
    assert_equal "collect.wingify.net", BrandUtil.get_events_hostname(false)
    assert_equal "Wingify-SDK", BrandUtil.get_log_prefix(false)
    assert_equal "Wingify", BrandUtil.get_brand_name(false)
  end
end

#test facade
class VwoFacadeTest < Minitest::Test
  def test_vwo_client_is_wingify_client
    assert_same WingifyClient, VWOClient
  end
  
  def test_vwo_builder_is_wingify_builder
    assert_same WingifyBuilder, VWOBuilder
  end

  def test_vwo_init_sets_is_via_vwo
    # Mock Wingify.init to capture options
    mock = Mocha::Mock.new
    mock.expects(:init).with do |options|
      options[:is_via_vwo] == true
    end.returns(true)
    
    Wingify.stubs(:init).with do |options|
      assert_equal true, options[:is_via_vwo]
      true
    end
    
    VWO.init({ sdk_key: "k", account_id: "1" })
  end
end
