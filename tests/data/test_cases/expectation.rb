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

module Data
  module TestCases
    class Expectation
      attr_accessor :is_enabled,
                    :int_variable,
                    :string_variable,
                    :float_variable,
                    :boolean_variable,
                    :json_variable,
                    :storage_data,
                    :should_return_same_variation
    end
  end
end
