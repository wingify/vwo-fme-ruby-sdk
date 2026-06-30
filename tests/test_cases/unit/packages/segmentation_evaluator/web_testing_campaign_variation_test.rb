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
require_relative '../../../../../lib/wingify/packages/segmentation_evaluator/utils/web_testing_segment_util'
require_relative '../../../../../lib/wingify/packages/segmentation_evaluator/evaluators/segment_evaluator'
require_relative '../../../../../lib/wingify/packages/segmentation_evaluator/evaluators/segment_operand_evaluator'
require_relative '../../../../../lib/wingify/packages/segmentation_evaluator/core/segmentation_manager'
require_relative '../../../../../lib/wingify/models/user/context_model'
require_relative '../../../../../lib/wingify/services/logger_service'

class WebTestingCampaignVariationTest < Minitest::Test
  def setup
    # Mock logger to avoid clutter
    LoggerService.stubs(:log)
  end

  def test_c_v_matches_when_user_is_in_campaign_with_variation
    map = { '1' => '1', '2' => '2' }
    result = WebTestingSegmentUtil.evaluate_web_testing_campaign_variation('1_1', map)
    assert_equal true, result[:result]
    assert_equal false, result[:invalid_format]
  end

  def test_c_v_false_when_variation_differs
    map = { '1' => '1', '2' => '2' }
    result = WebTestingSegmentUtil.evaluate_web_testing_campaign_variation('1_2', map)
    assert_equal false, result[:result]
  end

  def test_c_v_false_when_not_in_campaign
    map = { '1' => '1', '2' => '2' }
    result = WebTestingSegmentUtil.evaluate_web_testing_campaign_variation('99_1', map)
    assert_equal false, result[:result]
  end

  def test_c_not_v_when_in_campaign_and_variation_not_v
    map = { '1' => '1', '2' => '2' }
    result = WebTestingSegmentUtil.evaluate_web_testing_campaign_variation('1_!2', map)
    assert_equal true, result[:result]
  end

  def test_c_not_v_false_when_variation_equals_v
    map = { '1' => '1', '2' => '2' }
    result = WebTestingSegmentUtil.evaluate_web_testing_campaign_variation('1_!1', map)
    assert_equal false, result[:result]
  end

  def test_c_not_v_false_when_not_in_campaign
    map = { '1' => '1', '2' => '2' }
    result = WebTestingSegmentUtil.evaluate_web_testing_campaign_variation('99_!1', map)
    assert_equal false, result[:result]
  end

  def test_not_c_true_when_not_in_campaign
    map = { '1' => '1', '2' => '2' }
    result = WebTestingSegmentUtil.evaluate_web_testing_campaign_variation('!99', map)
    assert_equal true, result[:result]
  end

  def test_not_c_false_when_in_campaign
    map = { '1' => '1', '2' => '2' }
    result = WebTestingSegmentUtil.evaluate_web_testing_campaign_variation('!1', map)
    assert_equal false, result[:result]
  end

  def test_null_map_behaves_like_empty
    result = WebTestingSegmentUtil.evaluate_web_testing_campaign_variation('!1', nil)
    assert_equal true, result[:result]
    result = WebTestingSegmentUtil.evaluate_web_testing_campaign_variation('1_1', nil)
    assert_equal false, result[:result]
  end

  def test_invalid_operand_encoding
    map = { '1' => '1', '2' => '2' }
    result = WebTestingSegmentUtil.evaluate_web_testing_campaign_variation('bogus', map)
    assert_equal false, result[:result]
    assert_equal true, result[:invalid_format]
  end

  def test_multi_digit_campaign_and_variation_ids
    map = { '122' => '4' }
    assert_equal true, WebTestingSegmentUtil.evaluate_web_testing_campaign_variation('122_4', map)[:result]
    assert_equal true, WebTestingSegmentUtil.evaluate_web_testing_campaign_variation('122_!1', map)[:result]
    assert_equal false, WebTestingSegmentUtil.evaluate_web_testing_campaign_variation('!122', map)[:result]
  end

  def test_c_alone_in_campaign_c_with_any_variation
    map = { '1' => '1', '2' => '2' }
    assert_equal true, WebTestingSegmentUtil.evaluate_web_testing_campaign_variation('100', { '100' => '1' })[:result]
    assert_equal true, WebTestingSegmentUtil.evaluate_web_testing_campaign_variation('100', { '100' => '9' })[:result]
    assert_equal false, WebTestingSegmentUtil.evaluate_web_testing_campaign_variation('100', {})[:result]
    assert_equal false, WebTestingSegmentUtil.evaluate_web_testing_campaign_variation('100', { '99' => '1' })[:result]
    assert_equal false, WebTestingSegmentUtil.evaluate_web_testing_campaign_variation('100', map)[:result]
  end

  def test_normalize_web_testing_campaigns_map
    map = { 129 => 1, '14' => 2 }
    assert_equal({ '129' => '1', '14' => '2' }, WebTestingSegmentUtil.normalize_web_testing_campaigns_map(map))
  end

  # SegmentEvaluator campaignVariation DSL tests
  def test_or_branch_with_campaign_variation_and_json_string
    dsl = { 'or' => [{ 'campaignVariation' => '1_1' }] }
    context = ContextModel.new.model_from_dictionary({ id: 'user-1', uuid: 'test-uuid', platformVariables: { webTestingCampaigns: '{"1":"1"}' } })
    evaluator = SegmentEvaluator.new(context)
    
    assert_equal true, evaluator.is_segmentation_valid(dsl, {})
  end

  def test_object_web_testing_campaigns_without_stringify
    dsl = { 'or' => [{ 'campaignVariation' => '1_1' }] }
    context = ContextModel.new.model_from_dictionary({ id: 'user-1', uuid: 'test-uuid', platformVariables: { webTestingCampaigns: { '1' => 1 } } })
    evaluator = SegmentEvaluator.new(context)
    
    assert_equal true, evaluator.is_segmentation_valid(dsl, {})
  end

  def test_numeric_campaign_variation_without_platform_variables
    dsl = { 'not' => { 'or' => [{ 'campaignVariation' => 104 }] } }
    context = ContextModel.new.model_from_dictionary({ id: 'user-1', uuid: 'test-uuid' })
    evaluator = SegmentEvaluator.new(context)
    
    # In Ruby, SegmentEvaluator delegates directly, so if no platform variables, it fails, then 'not' makes it true
    assert_equal true, evaluator.is_segmentation_valid(dsl, {})
  end

  def test_numeric_campaign_variation_matches_when_in_campaign
    dsl = { 'or' => [{ 'campaignVariation' => 104 }] }
    context = ContextModel.new.model_from_dictionary({ id: 'user-1', uuid: 'test-uuid', platformVariables: { webTestingCampaigns: '{"104":"1"}' } })
    evaluator = SegmentEvaluator.new(context)
    
    assert_equal true, evaluator.is_segmentation_valid(dsl, {})
  end

  def test_not_in_campaign
    dsl = { 'or' => [{ 'campaignVariation' => '!1' }] }
    context = ContextModel.new.model_from_dictionary({ id: 'user-1', uuid: 'test-uuid', platformVariables: { webTestingCampaigns: '{}' } })
    evaluator = SegmentEvaluator.new(context)
    
    assert_equal true, evaluator.is_segmentation_valid(dsl, {})
  end

  def test_nested_not_and_campaign_variation
    dsl = { 'not' => { 'campaignVariation' => '1_1' } }
    context = ContextModel.new.model_from_dictionary({ id: 'user-1', uuid: 'test-uuid', platformVariables: { webTestingCampaigns: '{"1":"1"}' } })
    evaluator = SegmentEvaluator.new(context)
    
    assert_equal false, evaluator.is_segmentation_valid(dsl, {})
  end

  def test_operand_string_is_trimmed
    dsl = { 'or' => [{ 'campaignVariation' => '  1_1  ' }] }
    context = ContextModel.new.model_from_dictionary({ id: 'user-1', uuid: 'test-uuid', platformVariables: { webTestingCampaigns: '{"1":"1"}' } })
    evaluator = SegmentEvaluator.new(context)
    
    assert_equal true, evaluator.is_segmentation_valid(dsl, {})
  end

  def test_web_testing_campaigns_json_array_is_rejected
    dsl = { 'or' => [{ 'campaignVariation' => '1_1' }] }
    context = ContextModel.new.model_from_dictionary({ id: 'user-1', uuid: 'test-uuid', platformVariables: { webTestingCampaigns: '[]' } })
    evaluator = SegmentEvaluator.new(context)
    
    assert_equal false, evaluator.is_segmentation_valid(dsl, {})
  end

  def test_parse_web_testing_campaigns_duplicate_key_detection
    context = ContextModel.new.model_from_dictionary({ id: 'u1', uuid: 'test-uuid', platformVariables: { webTestingCampaigns: '{"1":0,"1":1}' } })
    
    LoggerService.expects(:log).with(
      LogLevelEnum::ERROR,
      'INVALID_WEB_TESTING_CAMPAIGNS_DUPLICATE_KEY',
      has_entries(an: ApiEnum::GET_FLAG)
    )
    
    result = WebTestingSegmentUtil.parse_web_testing_campaigns_from_context(context)
    assert_equal({ '1' => '1' }, result)
  end

  # SegmentationManager validate_segmentation fast-fail
  def test_positive_campaign_variation_with_no_platform_variables_fails_silently
    dsl = { 'or' => [{ 'campaignVariation' => '122_2' }] }
    context = ContextModel.new.model_from_dictionary({ id: 'user-1', uuid: 'test-uuid' })
    manager = SegmentationManager.new
    manager.attach_evaluator(SegmentEvaluator.new(context))
    
    assert_equal false, manager.validate_segmentation(dsl, {})
  end

  def test_not_plus_campaign_variation_with_no_platform_variables_fails_silently
    dsl = { 'not' => { 'or' => [{ 'campaignVariation' => '122' }] } }
    context = ContextModel.new.model_from_dictionary({ id: 'user-1', uuid: 'test-uuid' })
    manager = SegmentationManager.new
    manager.attach_evaluator(SegmentEvaluator.new(context))
    
    assert_equal false, manager.validate_segmentation(dsl, {})
  end

  def test_campaign_variation_with_web_testing_campaigns_present_evaluates_normally
    dsl = { 'not' => { 'or' => [{ 'campaignVariation' => '122' }] } }
    context = ContextModel.new.model_from_dictionary({ id: 'user-1', uuid: 'test-uuid', platformVariables: { webTestingCampaigns: '{}' } })
    manager = SegmentationManager.new
    manager.attach_evaluator(SegmentEvaluator.new(context))
    
    assert_equal true, manager.validate_segmentation(dsl, {})
  end
end
