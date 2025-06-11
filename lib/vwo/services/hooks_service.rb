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

require_relative '../models/vwo_options_model'
require_relative '../utils/data_type_util'

class HooksService
  attr_reader :decision

  def initialize(options)
    @callback = options.dig(:integrations, :callback)
    @is_callback_function = is_function?(@callback)
    @decision = {}
  end

  # Executes the callback
  # @param properties [Hash] Properties from the callback
  def execute(properties)
    @callback.call(properties) if @is_callback_function
  end

  # Sets properties to the decision object
  # @param properties [Hash] Properties to set
  def set(properties)
    @decision = properties if @is_callback_function
  end

  # Retrieves the decision object
  # @return [Hash] The decision object
  def get
    @decision
  end

  private

  # Helper function to check if a value is a function (assumed from data_type_util.rb)
  def is_function?(val)
    val.respond_to?(:call)
  end
end
