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

require_relative 'connector' # Import Connector class

class Storage
  @instance = nil

  attr_reader :connector
  attr_accessor :is_storage_enabled

  def initialize
    @connector = nil
    @is_storage_enabled = false
  end

  # Attach a connector (can be an instance or a class)
  def attach_connector(connector)
    if connector.is_a?(Class) # Check if it's a class before instantiating
      @connector = connector.new
    else
      @connector = connector
    end
    @connector
  end

  # Singleton instance method
  def self.instance
    @instance ||= new
  end

  # Get the attached connector
  def get_connector
    @connector
  end
end
