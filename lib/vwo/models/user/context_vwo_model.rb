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

class ContextVWOModel
    attr_accessor :location, :user_agent
  
    def initialize(location = {}, user_agent = {})
      @location = location
      @user_agent = user_agent
    end
  
    # Creates a model instance from a hash (dictionary)
    def model_from_dictionary(context)
      @location = context["location"] if context.key?("location")
      @user_agent = context["userAgent"] if context.key?("userAgent")
      self
    end

    def get_location
        @location
    end

    def get_ua_info
        @user_agent
    end
  end
  