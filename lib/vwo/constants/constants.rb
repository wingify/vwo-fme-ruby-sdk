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

# Constants file for Ruby SDK
  
# Define the Constants module
module Constants
  package_file = {
    name: 'vwo-fme-ruby-sdk',
    version: '1.0.0'
  }

  SDK_NAME = package_file[:name].freeze
  SDK_VERSION = package_file[:version].freeze

  MAX_TRAFFIC_PERCENT = 100
  MAX_TRAFFIC_VALUE = 10_000
  STATUS_RUNNING = 'RUNNING'.freeze

  SEED_VALUE = 1
  MAX_EVENTS_PER_REQUEST = 5_000
  DEFAULT_REQUEST_TIME_INTERVAL = 600 # 10 minutes in seconds
  DEFAULT_EVENTS_PER_REQUEST = 100

  SEED_URL = 'https://vwo.com'.freeze  # Define SEED_URL
  HTTP_PROTOCOL = 'http'.freeze
  HTTPS_PROTOCOL = 'https'.freeze

  SETTINGS = 'settings'.freeze
  SETTINGS_EXPIRY = 10_000_000
  SETTINGS_TIMEOUT = 50_000

  HOST_NAME = 'dev.visualwebsiteoptimizer.com'.freeze
  SETTINGS_ENDPOINT = '/server-side/v2-settings'.freeze
  WEBHOOK_SETTINGS_ENDPOINT = '/server-side/v2-pull'.freeze
  LOCATION_ENDPOINT = '/getLocation'.freeze

  VWO_FS_ENVIRONMENT = 'vwo_fs_environment'.freeze

  RANDOM_ALGO = 1

  API_VERSION = '1'.freeze

  VWO_META_MEG_KEY = '_vwo_meta_meg_'.freeze

  SHOULD_USE_THREADING = true
  MAX_POOL_SIZE = 5
end
  