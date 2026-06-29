# Copyright 2024-2026 Wingify Software Pvt. Ltd.
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
  SDK_VERSION = '1.55.0'.freeze

  # --- Brand-specific constants ---

  # SDK gem names (sent in every network request as the sdk name identifier)
  VWO_SDK_NAME     = 'vwo-fme-ruby-sdk'.freeze
  WINGIFY_SDK_NAME = 'wingify-fme-ruby-sdk'.freeze

  # Settings fetch hostnames
  VWO_HOST_NAME              = 'dev.visualwebsiteoptimizer.com'.freeze
  WINGIFY_SETTINGS_HOST_NAME = 'edge.wingify.net'.freeze

  # Collect / events hostnames (used for ALL outbound POST calls)
  WINGIFY_COLLECTION_HOST_NAME = 'collect.wingify.net'.freeze
  # Note: VWO uses VWO_HOST_NAME for both settings and events

  # Log prefixes shown in every log line
  VWO_LOG_PREFIX     = 'VWO-SDK'.freeze
  WINGIFY_LOG_PREFIX = 'Wingify-SDK'.freeze

  # Human-readable brand display names (used in log messages and error output)
  VWO_BRAND_DISPLAY_NAME     = 'VWO'.freeze
  WINGIFY_BRAND_DISPLAY_NAME = 'Wingify'.freeze

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
  WEB_UUID_REGEX = /\A[DJ][0-9A-Fa-f]{32}\z/.freeze
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

  REQUEST_TIMEOUT = 10 # 10 seconds

  # Retry mechanism constants
  MAX_RETRIES = 3
  INITIAL_RETRY_DELAY = 2 # seconds
  RETRY_BACKOFF_FACTOR = 2

  # Default retry configuration
  DEFAULT_RETRY_CONFIG = {
    should_retry: true,
    initial_delay: 2,
    max_retries: 3,
    backoff_multiplier: 2
  }.freeze

  # debugger event constants
  V2_SETTINGS = 'v2-settings'.freeze
  POLLING = 'polling'.freeze
  BATCH_EVENTS = 'batch-events'.freeze
  NETWORK_CALL_FAILURE_AFTER_MAX_RETRIES = 'NETWORK_CALL_FAILURE_AFTER_MAX_RETRIES'.freeze
  NETWORK_CALL_SUCCESS_WITH_RETRIES = 'NETWORK_CALL_SUCCESS_WITH_RETRIES'.freeze
  IMPACT_ANALYSIS = 'IMPACT_ANALYSIS'.freeze
end
