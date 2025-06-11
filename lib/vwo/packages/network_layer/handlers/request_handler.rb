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

require_relative '../models/global_request_model'
require_relative '../models/request_model'

class RequestHandler
  def create_request(request, config)
    return nil if config.get_base_url.nil? && request.get_url.nil?

    request.set_url(request.get_url || config.get_base_url)
    request.set_timeout(request.get_timeout || config.get_timeout)
    request.set_body(request.get_body || config.get_body)
    request.set_headers(request.get_headers || config.get_headers)

    request_query_params = request.get_query || {}
    config_query_params = config.get_query || {}

    config_query_params.each do |key, value|
      request_query_params[key] ||= value
    end

    request.set_query(request_query_params)
    request
  end
end
