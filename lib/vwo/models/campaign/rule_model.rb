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

class RuleModel
    attr_reader :status, :variation_id, :campaign_id, :type, :rule_key
  
    def initialize
      @status = false
      @variation_id = nil
      @campaign_id = nil
      @type = ''
      @rule_key = ''
    end
  
    # Creates a model instance from a hash (dictionary)
    def model_from_dictionary(rule)
      @type = rule["type"]
      @status = rule["status"]
      @variation_id = rule["variationId"]
      @campaign_id = rule["campaignId"]
      @rule_key = rule["ruleKey"]
      self
    end

    def get_type
        @type
    end
  
    def get_status
        @status
    end

    def get_variation_id
        @variation_id
    end

    def get_campaign_id
        @campaign_id
    end

    def get_rule_key
        @rule_key
    end
  end
  