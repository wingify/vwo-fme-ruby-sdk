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

# Constants file for Ruby SDK

# Define the Constants module
module Constants
  SDK_NAME = 'vwo-fme-ruby-sdk'.freeze
  SDK_VERSION = '1.4.1'.freeze

  MAX_TRAFFIC_PERCENT = 100
  MAX_TRAFFIC_VALUE = 10_000
  STATUS_RUNNING = 'RUNNING'.freeze

  SEED_VALUE = 1
  MAX_EVENTS_PER_REQUEST = 5_000
  DEFAULT_REQUEST_TIME_INTERVAL = 600 # 10 minutes in seconds
  DEFAULT_EVENTS_PER_REQUEST = 100
  MIN_REQUEST_TIME_INTERVAL = 2
  MIN_EVENTS_PER_REQUEST = 1

  SEED_URL = 'https://vwo.com'.freeze  # Define SEED_URL
  HTTP_PROTOCOL = 'http'.freeze
  HTTPS_PROTOCOL = 'https'.freeze

  SETTINGS = 'settings'.freeze
  SETTINGS_EXPIRY = 10_000_000
  SETTINGS_TIMEOUT = 50_000
  POLLING_INTERVAL = 600_000 # 10 minutes in milliseconds

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
  MAX_QUEUE_SIZE = 10000

  PRODUCT_NAME = 'fme'.freeze
end
