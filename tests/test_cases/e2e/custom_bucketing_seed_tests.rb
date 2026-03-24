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

require 'minitest/autorun'
require 'mocha/minitest'
require 'json'
require 'set'
require_relative '../../../lib/vwo'
require_relative '../../../lib/vwo/vwo_builder'
require_relative '../../../lib/vwo/services/logger_service'
require_relative '../../../lib/vwo/packages/storage/storage'
require_relative '../../../lib/vwo/utils/network_util'
require_relative 'test_helper'
require_relative '../../data/bucketing_seed_settings'

SETTINGS_WITH_SAME_SALT_DATA = JSON.parse(
  File.read(File.join(File.dirname(__FILE__), '../../data/settings/SETTINGS_WITH_SAME_SALT.json'))
)

class CustomBucketingSeedTest < Minitest::Test
  def setup_vwo(settings)
    @options = { sdk_key: 'test_sdk_key', account_id: 12345, threading: { enabled: false } }
    LoggerService.stubs(:log)
    NetworkUtil.stubs(:send_event)
    NetworkUtil.stubs(:send_post_api_request)
    stub_settings_service_valid!(@options)
    VWOBuilder.any_instance.stubs(:get_settings).returns(settings)
    Storage.instance.attach_connector(nil)
    VWO.init(@options)
  end

  def vars_hash(flag)
    flag.get_variables.each_with_object({}) { |v, h| h[v.key] = v.value }
  end

  # ─── No seed ─────────────────────────────────────────────────────────────────
  # Case 1: Two different users with NO seed should be bucketed by their own user IDs
  # and land in different variations (KaustubhVWO → Variation-1, RandomUserVWO → Default)
  def test_no_seed_different_users_get_different_variations
    vwo = setup_vwo(MOCK_SETTINGS_BUCKETING_SEED)
    flag1 = vwo.get_flag('featureOne', { id: 'KaustubhVWO' })
    flag2 = vwo.get_flag('featureOne', { id: 'RandomUserVWO' })
    refute_equal flag1.get_variable('kaus', nil), flag2.get_variable('kaus', nil)
  end

  # ─── Same seed ───────────────────────────────────────────────────────────────
  # Case 2: Two different users with the SAME bucketingSeed must get the same variation
  def test_same_seed_different_users_get_same_variation
    vwo = setup_vwo(MOCK_SETTINGS_BUCKETING_SEED)
    seed = 'common-seed-123'
    flag1 = vwo.get_flag('featureOne', { id: 'KaustubhVWO', bucketingSeed: seed })
    flag2 = vwo.get_flag('featureOne', { id: 'RandomUserVWO', bucketingSeed: seed })
    assert_equal flag1.get_variable('kaus', nil), flag2.get_variable('kaus', nil)
  end

  # Case 3: Same user ID with DIFFERENT seeds may land in different variations
  # Using seeds known to produce different results ('KaustubhVWO' vs 'RandomUserVWO')
  def test_different_seeds_same_user_gets_different_variations
    vwo = setup_vwo(MOCK_SETTINGS_BUCKETING_SEED)
    flag1 = vwo.get_flag('featureOne', { id: 'sameId', bucketingSeed: 'KaustubhVWO' })
    flag2 = vwo.get_flag('featureOne', { id: 'sameId', bucketingSeed: 'RandomUserVWO' })
    refute_equal flag1.get_variable('kaus', nil), flag2.get_variable('kaus', nil)
  end

  # Case 4: Empty string bucketingSeed is invalid → falls back to userId
  # Different users → different variations (same as no-seed case)
  def test_empty_string_seed_falls_back_to_user_id
    vwo = setup_vwo(MOCK_SETTINGS_BUCKETING_SEED)
    flag1 = vwo.get_flag('featureOne', { id: 'KaustubhVWO', bucketingSeed: '' })
    flag2 = vwo.get_flag('featureOne', { id: 'RandomUserVWO', bucketingSeed: '' })
    refute_equal flag1.get_variable('kaus', nil), flag2.get_variable('kaus', nil)
  end

  # ─── Salt + seed ─────────────────────────────────────────────────────────────
  # No seed, same salt: each user gets the same variation for both feature1 and feature2
  # because both features share identical salt values
  def test_salt_no_seed_same_user_gets_same_variation_across_both_flags
    vwo = setup_vwo(SETTINGS_WITH_SAME_SALT_DATA)
    (1..10).each do |i|
      flag1 = vwo.get_flag('feature1', { id: "user#{i}" })
      flag2 = vwo.get_flag('feature2', { id: "user#{i}" })
      assert_equal vars_hash(flag1), vars_hash(flag2),
        "user#{i}: expected same variation from feature1 and feature2 due to identical salt"
    end
  end

  # Same seed + same salt: all 10 users must get the identical variation
  # because bucketing is driven entirely by the shared seed
  def test_salt_with_common_seed_all_users_get_same_variation
    vwo = setup_vwo(SETTINGS_WITH_SAME_SALT_DATA)
    seed = 'common_seed_456'
    variations_seen = Set.new
    (1..10).each do |i|
      flag1 = vwo.get_flag('feature1', { id: "user#{i}", bucketingSeed: seed })
      flag2 = vwo.get_flag('feature2', { id: "user#{i}", bucketingSeed: seed })
      assert_equal vars_hash(flag1), vars_hash(flag2),
        "user#{i}: feature1 and feature2 should agree when same seed is used"
      variations_seen.add(vars_hash(flag1))
    end
    assert_equal 1, variations_seen.size,
      'All 10 users with the same bucketingSeed must land in exactly one variation'
  end

  # ─── Forced variation (whitelisting) ─────────────────────────────────────────
  # 'forcedWingify' is whitelisted to Variation-2 (value: 'var2') in the settings
  def test_whitelisted_user_gets_forced_variation_without_seed
    vwo = setup_vwo(MOCK_SETTINGS_BUCKETING_SEED)
    flag = vwo.get_flag('featureOne', { id: 'forcedWingify' })
    assert_equal 'var2', flag.get_variable('kaus', nil)
  end

  # bucketingSeed must NOT override forced/whitelisted variation
  def test_whitelisted_user_still_gets_forced_variation_when_seed_is_present
    vwo = setup_vwo(MOCK_SETTINGS_BUCKETING_SEED)
    flag = vwo.get_flag('featureOne', { id: 'forcedWingify', bucketingSeed: 'some-seed-xyz' })
    assert_equal 'var2', flag.get_variable('kaus', nil)
  end

end
