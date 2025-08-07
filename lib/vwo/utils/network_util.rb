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

require_relative '../enums/log_level_enum'
require_relative '../services/logger_service'
require_relative '../enums/headers_enum'
require_relative '../enums/http_method_enum'
require_relative '../enums/url_enum'
require_relative '../constants/constants'
require_relative '../packages/network_layer/manager/network_manager'
require_relative '../packages/network_layer/models/request_model'
require_relative '../packages/network_layer/models/response_model'
require_relative '../utils/url_util'
require_relative '../utils/uuid_util'
require_relative '../utils/usage_stats_util'

class NetworkUtil
  class << self
    # Converts hash map query parameters to URL-encoded query string
    # @param params [Hash] Hash containing query parameters
    # @return [String] URL-encoded query string
    def convert_params_to_string(params)
      return '' if params.nil? || params.empty?
      
      '?' + params.map do |key, value|
        "#{URI.encode_www_form_component(key.to_s)}=#{URI.encode_www_form_component(value.to_s)}"
      end.join('&')
    end

    # Returns the base properties for bulk operations
    def get_base_properties_for_bulk(account_id, user_id)
        {
            sId: get_current_unix_timestamp,  # Session ID
            u: UUIDUtil.get_uuid(user_id, account_id)  # UUID based on user and account ID
        }
    end

    # Returns settings path with sdkKey and accountId
    def get_settings_path(sdk_key, account_id)
        {
            i: sdk_key,  # API key
            r: rand,     # Random number for cache busting
            a: account_id  # Account ID
        }
    end

    # Returns the event tracking path
    def get_track_event_path(event, account_id, user_id)
        {
        event_type: event,  # Type of event
        account_id: account_id,  # Account ID
        uId: user_id,  # User ID
        u: UUIDUtil.get_uuid(user_id, account_id),  # UUID for user
        sdk: Constants::SDK_NAME,  # SDK Name
        'sdk-v': Constants::SDK_VERSION,  # SDK Version
        random: get_random_number,  # Random number for uniqueness
        sId: get_current_unix_timestamp,  # Session ID
        ed: JSON.generate({ p: 'server' })  # Additional encoded data
        }
    end

    # Returns query params for event batching
    def get_event_batching_query_params(account_id)
        {
        a: account_id,  # Account ID
        sd: Constants::SDK_NAME,  # SDK Name
        sv: Constants::SDK_VERSION  # SDK Version
        }
    end

    # Builds generic properties for different tracking calls
    def get_events_base_properties(event_name, visitor_user_agent = '', ip_address = '')
        sdk_key = SettingsService.instance.sdk_key || ''
        {
        en: event_name,
        a: SettingsService.instance.account_id,
        env: sdk_key,
        eTime: get_current_unix_timestamp_in_millis,
        random: get_random_number,
        p: 'FS',
        visitor_ua: visitor_user_agent || '',
        visitor_ip: ip_address || '',
        url: "#{UrlUtil.get_base_url}#{UrlEnum::EVENTS}"
        }
    end

    # Builds base payload for tracking events
    def _get_event_base_payload(user_id, event_name, visitor_user_agent = '', ip_address = '')
        uuid = UUIDUtil.get_uuid(user_id.to_s, SettingsService.instance.account_id)
        sdk_key = SettingsService.instance.sdk_key

        {
        d: {
            msgId: "#{uuid}-#{get_current_unix_timestamp_in_millis}",
            visId: uuid,
            sessionId: get_current_unix_timestamp,
            event: {
            props: {
                vwo_sdkName: Constants::SDK_NAME,
                vwo_sdkVersion: Constants::SDK_VERSION,
                vwo_envKey: sdk_key
            },
            name: event_name,
            time: get_current_unix_timestamp_in_millis
            },
            visitor: {
            props: {
                vwo_fs_environment: sdk_key
            }
            }
        }
        }
    end

    # Builds track-user payload data
    def get_track_user_payload_data(user_id, event_name, campaign_id, variation_id, visitor_user_agent = '', ip_address = '')
        properties = _get_event_base_payload(user_id, event_name, visitor_user_agent, ip_address)
        properties[:d][:event][:props][:id] = campaign_id
        properties[:d][:event][:props][:variation] = variation_id
        properties[:d][:event][:props][:isFirst] = 1

        # Only add visitor_ua and visitor_ip if they are non-null
        properties[:d][:visitor_ua] = visitor_user_agent if visitor_user_agent && !visitor_user_agent.empty?
        properties[:d][:visitor_ip] = ip_address if ip_address && !ip_address.empty?

        # check if usage stats size is greater than 0
        usage_stats = UsageStatsUtil.get_usage_stats
        if usage_stats.size > 0
            properties[:d][:event][:props][:vwoMeta] = usage_stats
        end
        
        LoggerService.log(LogLevelEnum::DEBUG, "IMPRESSION_FOR_TRACK_USER", {
            accountId: SettingsService.instance.account_id,
            userId: user_id,
            campaignId: campaign_id
        })
        
        properties
    end

    # Constructs payload for tracking goals with custom event properties
    def get_track_goal_payload_data(user_id, event_name, event_properties, visitor_user_agent = '', ip_address = '')
        properties = _get_event_base_payload(user_id, event_name, visitor_user_agent, ip_address)
        properties[:d][:event][:props][:isCustomEvent] = true

        if SettingsService.instance.is_gateway_service_provided
            properties[:d][:event][:props][:variation] = 1
            properties[:d][:event][:props][:id] = 1  # Temporary value for ID
        end
        
        if event_properties.is_a?(Hash) && !event_properties.empty?
        event_properties.each { |key, value| properties[:d][:event][:props][key] = value }
        end
        
        LoggerService.log(LogLevelEnum::DEBUG, "IMPRESSION_FOR_TRACK_GOAL", {
            eventName: event_name,
            accountId: SettingsService.instance.account_id,
            userId: user_id
        })
        
        properties
    end

    def get_attribute_payload_data(user_id, event_name, event_properties, visitor_user_agent = '', ip_address = '')
        properties = _get_event_base_payload(user_id, event_name, visitor_user_agent, ip_address)
        properties[:d][:event][:props][:isCustomEvent] = true

        if event_properties.is_a?(Hash) && !event_properties.empty?
            event_properties.each { |key, value| properties[:d][:visitor][:props][key] = value }
        end

        LoggerService.log(LogLevelEnum::DEBUG, "IMPRESSION_FOR_SYNC_VISITOR_PROP", {
            eventName: event_name,
            accountId: SettingsService.instance.account_id,
            userId: user_id
        })
        properties
    end

    # Constructs the payload for init called event.
    # @param event_name - The name of the event.
    # @param settings_fetch_time - Time taken to fetch settings in milliseconds.
    # @param sdk_init_time - Time taken to initialize the SDK in milliseconds.
    # @returns The constructed payload with required fields.
    def get_sdk_init_event_payload(event_name, settings_fetch_time, sdk_init_time)
        user_id = SettingsService.instance.account_id + "_" + SettingsService.instance.sdk_key
        properties = _get_event_base_payload(user_id, event_name, nil, nil)
        properties[:d][:event][:props][:vwo_fs_environment] = SettingsService.instance.sdk_key
        properties[:d][:event][:props][:product] = Constants::PRODUCT_NAME
        data = {
            "isSDKInitialized": true,
            "settingsFetchTime": settings_fetch_time,
            "sdkInitTime": sdk_init_time
        }
        properties[:d][:event][:props][:data] = data
        properties
    end

    # Sends a POST API request with given properties and payload
    def send_post_api_request(properties, payload)
        network_instance = NetworkManager.instance
        headers = {}
        headers[HeadersEnum::USER_AGENT] = payload[:d][:visitor_ua] if payload[:d][:visitor_ua]
        headers[HeadersEnum::IP] = payload[:d][:visitor_ip] if payload[:d][:visitor_ip]

        request = RequestModel.new(
        UrlUtil.get_base_url,
        HttpMethodEnum::POST,
        UrlEnum::EVENTS,
        properties,
        payload,
        headers,
        SettingsService.instance.protocol,
        SettingsService.instance.port
        )

        begin 
            if network_instance.get_client.get_should_use_threading
                network_instance.get_client.get_thread_pool.post {
                    response = network_instance.post(request)
                    if response.get_status_code == 200
                        UsageStatsUtil.clear_usage_stats
                    end
                    response
                }
            else
                response = network_instance.post(request)
                if response.get_status_code == 200
                    UsageStatsUtil.clear_usage_stats
                end
                response
            end
        rescue ResponseModel => err
            LoggerService.log(LogLevelEnum::ERROR, "NETWORK_CALL_FAILED", {
                method: HttpMethodEnum::POST,
                err: err.is_a?(Hash) ? err.to_json : err
            })
        end
    end

    # Sends an event to VWO (generic event sender).
    # @param properties - Query parameters for the request.
    # @param payload - The payload for the request.
    # @param event_name - The name of the event to send.
    def send_event(properties, payload)
        network_instance = NetworkManager.instance
        headers = {}
        headers[HeadersEnum::USER_AGENT] = payload[:d][:visitor_ua] if payload[:d][:visitor_ua]
        headers[HeadersEnum::IP] = payload[:d][:visitor_ip] if payload[:d][:visitor_ip]

        request = RequestModel.new(
            UrlUtil.get_base_url,
            HttpMethodEnum::POST,
            UrlEnum::EVENTS,
            properties,
            payload,
            headers,
            SettingsService.instance.protocol,
            SettingsService.instance.port
        )

        begin 
            if network_instance.get_client.get_should_use_threading
                network_instance.get_client.get_thread_pool.post {
                    response = network_instance.post(request)
                    response
                }
            else
                response = network_instance.post(request)
                response
            end
        rescue ResponseModel => err
        end
    end

    # Sends a GET API request to the specified endpoint with given properties
    def send_get_api_request(properties, endpoint)
        network_instance = NetworkManager.instance
        
        request = RequestModel.new(
        UrlUtil.get_base_url,
        HttpMethodEnum::GET,
        endpoint,
        properties,
        nil,
        nil,
        SettingsService.Instance.protocol,
        SettingsService.Instance.port
        )
        
        begin
            network_instance.get(request)
        rescue StandardError => err
            LoggerService.log(LogLevelEnum::ERROR, "NETWORK_CALL_FAILED", {
                method: HttpMethodEnum::GET,
                err: err.is_a?(Hash) ? err.to_json : err
            })
        end
    end
  end
end