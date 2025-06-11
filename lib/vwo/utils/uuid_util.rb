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

require 'uuidtools'
require 'securerandom'

SEED_URL = 'https://vwo.com' # Replace with actual SEED_URL

class UUIDUtil
  # Generates a random UUID based on an API key.
  #
  # @param sdk_key [String] The API key used to generate a namespace for the UUID.
  # @return [String] A random UUID string.
  def self.get_random_uuid(sdk_key)
    namespace = UUIDTools::UUID.sha1_create(UUIDTools::UUID_DNS_NAMESPACE, sdk_key)
    random_uuid = UUIDTools::UUID.sha1_create(namespace, SecureRandom.uuid)
    random_uuid.to_s
  end

  # Generates a UUID for a user based on their user_id and account_id.
  #
  # @param user_id [String] The user's ID.
  # @param account_id [String] The account ID associated with the user.
  # @return [String] A UUID string formatted without dashes and in uppercase.
  def self.get_uuid(user_id, account_id)
    vwo_namespace = UUIDTools::UUID.sha1_create(UUIDTools::UUID_URL_NAMESPACE, SEED_URL)
    user_id_namespace = generate_uuid(account_id, vwo_namespace)
    uuid_for_user_id_account_id = generate_uuid(user_id, user_id_namespace)

    uuid_for_user_id_account_id.to_s.delete('-').upcase
  end

  # Helper function to generate a UUID v5 based on a name and a namespace.
  #
  # @param name [String] The name from which to generate the UUID.
  # @param namespace [UUIDTools::UUID] The namespace used to generate the UUID.
  # @return [UUIDTools::UUID] A UUID string or nil if inputs are invalid.
  def self.generate_uuid(name, namespace)
    return nil if name.nil? || namespace.nil?
    # Convert name to string to handle integer inputs
    name_str = name.to_s
    UUIDTools::UUID.sha1_create(namespace, name_str)
  end
end
