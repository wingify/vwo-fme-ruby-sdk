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

module DataTypeUtil
    # Checks if the value is a Hash (object in JS)
    def self.is_object(val)
      val.is_a?(Hash)
    end
  
    # Checks if the value is an Array
    def self.is_array(val)
      val.is_a?(Array)
    end
  
    # Checks if the value is nil
    def self.is_null(val)
      val.nil?
    end
  
    # Checks if the value is undefined (not applicable in Ruby, so return false)
    def self.is_undefined(val)
      false
    end
  
    # Checks if the value is defined (not nil)
    def self.is_defined(val)
      !val.nil?
    end
  
    # Checks if the value is a Number (including NaN)
    def self.is_number(val)
      val.is_a?(Numeric)
    end
  
    # Checks if the value is a String
    def self.is_string(val)
      val.is_a?(String)
    end
  
    # Checks if the value is a Boolean
    def self.is_boolean(val)
      val.is_a?(TrueClass) || val.is_a?(FalseClass)
    end
  
    # Checks if the value is NaN (only applicable for Float in Ruby)
    def self.is_nan(val)
      val.is_a?(Float) && val.nan?
    end
  
    # Checks if the value is a Date
    def self.is_date(val)
      val.is_a?(Date) || val.is_a?(Time) || val.is_a?(DateTime)
    end
  
    # Checks if the value is a Function (Proc or Lambda in Ruby)
    def self.is_function(val)
      val.is_a?(Proc) || val.is_a?(Method)
    end
  
    # Checks if the value is a Regular Expression
    def self.is_regex(val)
      val.is_a?(Regexp)
    end
  
    # Determines the type of the given value
    def self.get_type(val)
      case
      when is_object(val)
        "Object"
      when is_array(val)
        "Array"
      when is_null(val)
        "Null"
      when is_undefined(val)
        "Undefined"
      when is_nan(val)
        "NaN"
      when is_number(val)
        "Number"
      when is_string(val)
        "String"
      when is_boolean(val)
        "Boolean"
      when is_date(val)
        "Date"
      when is_regex(val)
        "Regex"
      when is_function(val)
        "Function"
      else
        "Unknown Type"
      end
    end
  end