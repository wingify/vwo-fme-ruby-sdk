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

class MetricModel
    attr_reader :id, :identifier, :type
  
    def initialize
      @id = nil
      @identifier = ''
      @type = ''
    end
  
    # Creates a model instance from a hash (dictionary)
    def model_from_dictionary(metric)
      @identifier = metric["identifier"]
      @id = metric["id"]
      @type = metric["type"]
      self
    end

    def get_id
        @id
    end

    def get_identifier
        @identifier
    end

    def get_type
        @type
    end
  end
  