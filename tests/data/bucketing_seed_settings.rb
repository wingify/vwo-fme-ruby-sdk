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

MOCK_SETTINGS_BUCKETING_SEED = {
  'version' => 1,
  'sdkKey' => 'abcdef',
  'accountId' => 123456,
  'campaigns' => [
    {
      'segments' => {},
      'status' => 'RUNNING',
      'variations' => [
        {
          'weight' => 100,
          'segments' => {},
          'id' => 1,
          'variables' => [{ 'id' => 1, 'type' => 'string', 'value' => 'def', 'key' => 'kaus' }],
          'name' => 'Rollout-rule-1'
        }
      ],
      'type' => 'FLAG_ROLLOUT',
      'isAlwaysCheckSegment' => false,
      'isForcedVariationEnabled' => false,
      'name' => 'featureOne : Rollout',
      'key' => 'featureOne_rolloutRule1',
      'id' => 1
    },
    {
      'segments' => {},
      'status' => 'RUNNING',
      'key' => 'featureOne_testingRule1',
      'type' => 'FLAG_TESTING',
      'isAlwaysCheckSegment' => false,
      'name' => 'featureOne : Testing rule 1',
      'isForcedVariationEnabled' => true,
      'variations' => [
        {
          'weight' => 50,
          'segments' => {},
          'id' => 1,
          'variables' => [{ 'id' => 1, 'type' => 'string', 'value' => 'def', 'key' => 'kaus' }],
          'name' => 'Default'
        },
        {
          'weight' => 50,
          'segments' => {},
          'id' => 2,
          'variables' => [{ 'id' => 1, 'type' => 'string', 'value' => 'var1', 'key' => 'kaus' }],
          'name' => 'Variation-1'
        },
        {
          'weight' => 0,
          'segments' => { 'or' => [{ 'user' => 'forcedWingify' }] },
          'id' => 3,
          'variables' => [{ 'id' => 1, 'type' => 'string', 'value' => 'var2', 'key' => 'kaus' }],
          'name' => 'Variation-2'
        },
        {
          'weight' => 0,
          'segments' => {},
          'id' => 4,
          'variables' => [{ 'id' => 1, 'type' => 'string', 'value' => 'var3', 'key' => 'kaus' }],
          'name' => 'Variation-3'
        }
      ],
      'id' => 2,
      'percentTraffic' => 100
    }
  ],
  'features' => [
    {
      'impactCampaign' => {},
      'rules' => [
        { 'campaignId' => 1, 'type' => 'FLAG_ROLLOUT', 'ruleKey' => 'rolloutRule1', 'variationId' => 1 },
        { 'type' => 'FLAG_TESTING', 'ruleKey' => 'testingRule1', 'campaignId' => 2 }
      ],
      'status' => 'ON',
      'key' => 'featureOne',
      'metrics' => [{ 'type' => 'CUSTOM_GOAL', 'identifier' => 'e1', 'id' => 1 }],
      'type' => 'FEATURE_FLAG',
      'name' => 'featureOne',
      'id' => 1
    }
  ]
}
