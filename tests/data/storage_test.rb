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

class StorageTest
    # Initialize a hash to store the data
    def initialize
      @storage = {}
    end
  
    # Overriding the `set` method to store data in the hash
    def set(data)
      feature_key = data[:feature_key]
      user_id = data[:user_id]
  
      # Generate the key to store the data
      key = "#{feature_key}_#{user_id}"
  
      # Create a map to store the data
      value = {
        rollout_key: data[:rollout_key],
        rollout_variation_id: data[:rollout_variation_id],
        experiment_key: data[:experiment_key],
        experiment_variation_id: data[:experiment_variation_id]
      }
  
      # Store the value in the storage
      @storage[key] = value
    end
  
    # Overriding the `get` method to retrieve data from the hash
    def get(feature_key, user_id)
      key = "#{feature_key}_#{user_id}"
  
      # Check if the key exists in the storage
      if @storage.key?(key)
        return @storage[key]
      end
  
      # Return nil if key does not exist
      nil
    end

    def clear
      @storage = {}
    end
  end
