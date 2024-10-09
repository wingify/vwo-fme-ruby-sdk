# Copyright 2024 Wingify Software Pvt. Ltd.
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

module VWO
  class FeatureFlagResponse
    def initialize(is_enabled, variables = [])
      @is_enabled = is_enabled
      @variables = variables
    end

    # Method to check if the flag is enabled
    def is_enabled
      @is_enabled
    end

    # Method to get all variables
    def get_variables
      @variables
    end

    # Method to get a specific variable by key, with a fallback default value
    def get_variable(key, default_value)
      variable = @variables.find { |var| var['key'] == key }
      variable ? variable['value'] : default_value
    end
  end
end