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

require_relative '../user/context_model'

class StorageDataModel
  attr_accessor :feature_key, :context, :rollout_id, :rollout_key, :rollout_variation_id,
                :experiment_id, :experiment_key, :experiment_variation_id

  def initialize
    @feature_key = ''
    @context = nil
    @rollout_id = nil
    @rollout_key = ''
    @rollout_variation_id = nil
    @experiment_id = nil
    @experiment_key = ''
    @experiment_variation_id = nil
  end

  # Creates a model instance from a hash (dictionary)
  def model_from_dictionary(storage_data)
    @feature_key = storage_data[:feature_key]
    @context = storage_data[:context]
    @rollout_id = storage_data[:rollout_id]
    @rollout_key = storage_data[:rollout_key]
    @rollout_variation_id = storage_data[:rollout_variation_id]
    @experiment_id = storage_data[:experiment_id]
    @experiment_key = storage_data[:experiment_key]
    @experiment_variation_id = storage_data[:experiment_variation_id]
    self
  end
end
