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

# Constructs a message by replacing placeholders in a template with corresponding values from a data hash.
#
# @param template [String] The message template containing placeholders in the format `{key}`.
# @param data [Hash] An object containing keys and values used to replace the placeholders in the template.
# @return [String] The constructed message with all placeholders replaced by their corresponding values from the data hash.
def build_message(template, data = {})
    begin
      template.gsub(/\{([0-9a-zA-Z_]+)\}/) do |match|
        key = match.tr('{}', '') # Extract the key from `{key}`
        
        # Check for escaped placeholders like `{{key}}`
        if template[template.index(match) - 1] == '{' && template[template.index(match) + match.length] == '}'
          key
        else
          value = data[key.to_sym] || data[key] # Support both string and symbol keys
  
          # Return empty string if key is missing
          next '' if value.nil?
  
          # If value is a callable (Proc/Lambda), execute it
          value.respond_to?(:call) ? value.call : value
        end
      end
    rescue StandardError
      template # Return the original template in case of an error
    end
  end
  