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

class GetFlagResponse
  attr_reader :is_enabled, :get_variables, :get_variable, :get_uuid, :get_session_id
  
  def initialize(is_enabled, variables = [], uuid = nil, session_id = nil)
    @is_enabled = is_enabled
    @variables = variables
    @uuid = uuid
    @session_id = session_id
  end
  
  # Define method for is_enabled
  def is_enabled
    @is_enabled
  end

  # Define method for get_variables
  def get_variables
    @variables
  end

  # Define method for get_variable
  def get_variable(key, default_value = nil)
      variable = @variables.find { |var| var.key == key }
      variable ? variable.value : default_value
  end

  # Define method for get_uuid
  def get_uuid
    @uuid
  end

  # Define method for get_session_id
  def get_session_id
    @session_id
  end
end