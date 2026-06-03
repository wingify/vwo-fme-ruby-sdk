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

require_relative 'wingify'
require_relative 'wingify/wingify_client'
require_relative 'wingify/wingify_builder'

# Map existing VWO classes to Wingify aliases to maintain 100% backward compatibility
VWOClient = WingifyClient
VWOBuilder = WingifyBuilder

module VWO
  # Backward compatible VWO facade
  # It intercepts the init call, forces the is_via_vwo flag, and forwards to Wingify core.
  def self.init(options)
    options[:is_via_vwo] = true
    Wingify.init(options)
  end

  def self.get_uuid(user_id, account_id)
    Wingify.get_uuid(user_id, account_id)
  end

  # Keep VWO.new backward compatible for any customers manually instantiating it,
  # although standard docs recommend VWO.init
  def self.new(options)
    init(options)
  end
end