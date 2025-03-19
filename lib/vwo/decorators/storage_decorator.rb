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

require_relative '../enums/storage_enum'
require_relative '../models/campaign/feature_model'
require_relative '../models/campaign/variation_model'
require_relative '../services/storage_service'
require_relative '../models/user/context_model'
require_relative '../services/logger_service'
require_relative '../enums/log_level_enum'
class StorageDecorator
  # Retrieves a feature from storage based on the feature key and user.
  # @param feature_key [String] The key of the feature to retrieve.
  # @param context [ContextModel] The user object.
  # @param storage_service [StorageService] The storage service instance.
  # @return [Hash, StorageEnum] The retrieved feature or relevant status.
  def get_feature_from_storage(feature_key, context, storage_service)
    campaign_map = storage_service.get_data_from_storage(feature_key, context)

    case campaign_map
    when StorageEnum::STORAGE_UNDEFINED, StorageEnum::NO_DATA_FOUND,
         StorageEnum::CAMPAIGN_PAUSED, StorageEnum::WHITELISTED_VARIATION
      nil # Return nil when there's no valid data
    when StorageEnum::INCORRECT_DATA, StorageEnum::VARIATION_NOT_FOUND
      campaign_map # Return the relevant error constant
    else
      campaign_map # Return valid stored data
    end
  end

  # Sets data in storage based on the provided data object.
  # @param data [Hash] The data to be stored, including feature key and user details.
  # @param storage_service [StorageService] The storage service instance.
  def set_data_in_storage(data, storage_service)
    feature_key = data[:feature_key]
    context = data[:context]
    rollout_id = data[:rollout_id]
    rollout_key = data[:rollout_key]
    rollout_variation_id = data[:rollout_variation_id]
    experiment_id = data[:experiment_id]
    experiment_key = data[:experiment_key]
    experiment_variation_id = data[:experiment_variation_id]

    if feature_key.nil?
      LoggerService.log(LogLevelEnum::ERROR, "STORING_DATA_ERROR", { key: 'featureKey' })
      raise 'Feature key is missing'
    end

    if context.nil? || context.id.nil?
      LoggerService.log(LogLevelEnum::ERROR, "STORING_DATA_ERROR", { key: 'Context or Context.id' })
      raise 'Context ID is missing'
    end

    if rollout_key && !experiment_key && !rollout_variation_id
      LoggerService.log(LogLevelEnum::ERROR, "STORING_DATA_ERROR", { key: 'Variation:(rolloutKey, experimentKey or rolloutVariationId)' })
      raise 'Invalid rollout variation'
    end

    if experiment_key && !experiment_variation_id
      LoggerService.log(LogLevelEnum::ERROR, "STORING_DATA_ERROR", { key: 'Variation:(experimentKey or rolloutVariationId)' })
      raise 'Invalid experiment variation'
    end

    storage_service.set_data_in_storage({
      feature_key: feature_key,
      user_id: context.id,
      rollout_id: rollout_id,
      rollout_key: rollout_key,
      rollout_variation_id: rollout_variation_id,
      experiment_id: experiment_id,
      experiment_key: experiment_key,
      experiment_variation_id: experiment_variation_id
    })
  end
end
