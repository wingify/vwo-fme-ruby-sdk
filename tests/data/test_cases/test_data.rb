# Copyright 2025 Wingify Software Pvt. Ltd.
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

require_relative '../../../../lib/vwo/models/user/context_model'

class TestData
  # Create getters and setters for all instance variables
  attr_accessor :description,
                :settings,
                :context,
                :user_ids,
                :expectation,
                :feature_key,
                :feature_key2

  def initialize
    @description = nil
    @settings = nil
    @context = nil
    @user_ids = []
    @expectation = nil
    @feature_key = nil
    @feature_key2 = nil
  end
end
