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

require 'murmurhash3'

class DecisionMaker
  SEED_VALUE = 1 # Seed value for the hash function

  # Generates a bucket value based on the hash value, maximum value, and an optional multiplier.
  #
  # @param hash_value [Integer] The hash value used for calculation.
  # @param max_value [Integer] The maximum value for bucket scaling.
  # @param multiplier [Integer] Optional multiplier to adjust the value (default: 1).
  # @return [Integer] The calculated bucket value.
  def generate_bucket_value(hash_value, max_value, multiplier = 1)
    ratio = hash_value.to_f / (2**32)
    multiplied_value = ((max_value * ratio) + 1) * multiplier
    multiplied_value.floor
  end

  # Gets the bucket value for a user based on the hash key and maximum value.
  #
  # @param hash_key [String] The hash key for the user.
  # @param max_value [Integer] The maximum value for bucket scaling (default: 100).
  # @return [Integer] The calculated bucket value for the user.
  def get_bucket_value_for_user(hash_key, max_value = 100)
    hash_value = MurmurHash3::V32.str_hash(hash_key, SEED_VALUE)
    generate_bucket_value(hash_value, max_value)
  end

  # Calculates the bucket value for a given string with an optional multiplier and maximum value.
  #
  # @param str [String] The input string to calculate the bucket value for.
  # @param multiplier [Integer] Optional multiplier to adjust the value (default: 1).
  # @param max_value [Integer] The maximum value for bucket scaling (default: 10000).
  # @return [Integer] The calculated bucket value.
  def calculate_bucket_value(str, multiplier = 1, max_value = 10000)
    hash_value = generate_hash_value(str)
    generate_bucket_value(hash_value, max_value, multiplier)
  end

  # Generates the hash value for a given hash key using MurmurHash v3.
  #
  # @param hash_key [String] The hash key for which the hash value is generated.
  # @return [Integer] The generated hash value.
  def generate_hash_value(hash_key)
    MurmurHash3::V32.str_hash(hash_key, SEED_VALUE)
  end
end
