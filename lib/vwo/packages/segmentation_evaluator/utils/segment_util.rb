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

require 'json'

# Utility function to check if a value is an object (excluding arrays and other types)
def is_object?(val)
  val.is_a?(Hash)
end

# Extracts the first key-value pair from the provided object.
# @param obj [Hash] The object from which to extract the key-value pair.
# @return [Hash, nil] A hash containing the first key and value, or nil if input is not a hash.
def get_key_value(obj)
  return nil unless is_object?(obj)

  key = obj.keys.first
  return nil unless key

  { key: key, value: obj[key] }
end

# Matches a string against a regular expression and returns the match result.
# @param string [String] The string to match against the regex.
# @param regex [String] The regex pattern as a string.
# @return [Array, nil] The results of the regex match, or nil if an error occurs.
def match_with_regex(string, regex)
  begin
    return string.match(Regexp.new(regex))
  rescue StandardError
    return nil
  end
end