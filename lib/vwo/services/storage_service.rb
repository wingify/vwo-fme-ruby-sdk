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
require_relative '../models/user/context_model'
require_relative '../packages/storage/storage'
require_relative '../services/logger_service'
require_relative '../enums/log_level_enum'
require_relative '../utils/data_type_util'

class StorageService
  attr_accessor :storage_data

  def initialize
    @storage_data = {}
  end

  # Retrieves data from storage based on the feature key and user ID.
  # @param feature_key [String] The key to identify the feature data.
  # @param context [ContextModel] The user context containing an ID.
  # @return [Hash] The data retrieved or a storage status enum.
  def get_data_from_storage(feature_key, context)
    storage_instance = Storage.instance.get_connector

    # Check if the storage instance is available
    return StorageEnum::STORAGE_UNDEFINED if DataTypeUtil.is_null(storage_instance) || DataTypeUtil.is_undefined(storage_instance)

    begin
      data = storage_instance.get(feature_key, context.get_id)
      return data.nil? ? StorageEnum::NO_DATA_FOUND : data
    rescue StandardError => e
      LoggerService.log(LogLevelEnum::ERROR, "STORED_DATA_ERROR", { err: e.message })
      return StorageEnum::NO_DATA_FOUND
    end
  end

  # Stores data in the storage.
  # @param data [Hash] The data to be stored.
  # @return [Boolean] True if data is successfully stored, otherwise false.
  def set_data_in_storage(data)
    storage_instance = Storage.instance.get_connector

    # Check if the storage instance is available
    return false if storage_instance.nil?

    begin
      storage_instance.set(data)
      return true
    rescue StandardError
      LoggerService.log(LogLevelEnum::ERROR, "STORED_DATA_ERROR", { err: e.message })
      return false
    end
  end
end
