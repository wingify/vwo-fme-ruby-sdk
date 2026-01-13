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
require_relative '../models/user/context_model'
require_relative '../utils/log_message_util'
require_relative '../utils/function_util'
require_relative '../enums/api_enum'

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
    def get_events_base_properties(event_name, visitor_user_agent = '', ip_address = '', is_usage_stats_event = false, usage_stat_account_id = '')
        properties = {
            en: event_name,
            a: SettingsService.instance.account_id,
            eTime: get_current_unix_timestamp_in_millis,
            random: get_random_number,
            p: 'FS',
            visitor_ua: visitor_user_agent || '',
            visitor_ip: ip_address || '',
            url: "#{UrlUtil.get_base_url}#{UrlEnum::EVENTS}"
        }

        if !is_usage_stats_event
            # set env key for standard sdk events
            properties[:env] = SettingsService.instance.sdk_key
        else
            # set env key for usage stats events
            properties[:a] = usage_stat_account_id
        end

        properties
    end

    # Builds base payload for tracking events
    def _get_event_base_payload(user_id, event_name, visitor_user_agent = '', ip_address = '', is_usage_stats_event = false, usage_stat_account_id = '')
        account_id = SettingsService.instance.account_id

        if is_usage_stats_event
            account_id = usage_stat_account_id
        end

        uuid = UUIDUtil.get_uuid(user_id.to_s, account_id.to_s)
        sdk_key = SettingsService.instance.sdk_key

        payload = {
            d: {
                msgId: "#{uuid}-#{get_current_unix_timestamp_in_millis}",
                visId: uuid,
                sessionId: get_current_unix_timestamp,
                event: {
                    props: {
                        vwo_sdkName: Constants::SDK_NAME,
                        vwo_sdkVersion: Constants::SDK_VERSION,
                    },
                    name: event_name,
                    time: get_current_unix_timestamp_in_millis
                }
            }
        }

        if !is_usage_stats_event
            # set env key for standard sdk events
            payload[:d][:event][:props][:vwo_envKey] = sdk_key

            # set visitor props for standard sdk events
            payload[:d][:visitor] = {
                props: {
                    vwo_fs_environment: sdk_key
                }
            }
        end

        payload
    end

    # Builds track-user payload data
    def get_track_user_payload_data(event_name, campaign_id, variation_id, context)
        user_id = context.get_id
        visitor_user_agent = context.get_user_agent
        ip_address = context.get_ip_address
        custom_variables = context.get_custom_variables
        post_segmentation_variables = context.get_post_segmentation_variables

        properties = _get_event_base_payload(user_id, event_name, visitor_user_agent, ip_address)

        properties[:d][:event][:props][:id] = campaign_id
        properties[:d][:event][:props][:variation] = variation_id
        properties[:d][:event][:props][:isFirst] = 1

        # Only add visitor_ua and visitor_ip if they are non-null
        properties[:d][:visitor_ua] = visitor_user_agent if visitor_user_agent && !visitor_user_agent.empty?
        properties[:d][:visitor_ip] = ip_address if ip_address && !ip_address.empty?

        # Add post-segmentation variables if they exist in custom variables
        if post_segmentation_variables&.any? && custom_variables&.any?
            post_segmentation_variables.each do |key|
                # Try to get value using string key first, then symbol key
                value = custom_variables[key] || custom_variables[key.to_sym]
                if value
                    properties[:d][:visitor][:props][key] = value
                end
            end
        end

        # Add IP address as a standard attribute if available
        if ip_address && !ip_address.empty?
          properties[:d][:visitor][:props][:ip] = ip_address
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
        user_id = SettingsService.instance.account_id.to_s + "_" + SettingsService.instance.sdk_key
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

    # Constructs the payload for usage stats called event.
    # @param event_name - The name of the event.
    # @param usage_stats_account_id - The account id for usage stats.
    # @returns The constructed payload with required fields.
    def get_sdk_usage_stats_payload_data(event_name, usage_stats_account_id)
        user_id = SettingsService.instance.account_id.to_s + "_" + SettingsService.instance.sdk_key
        properties = _get_event_base_payload(user_id, event_name, nil, nil, true, usage_stats_account_id)
        properties[:d][:event][:props][:product] = Constants::PRODUCT_NAME
        properties[:d][:event][:props][:vwoMeta] = UsageStatsUtil.get_usage_stats
        properties
    end

    # Sends a POST API request with given properties and payload
    def send_post_api_request(properties, payload, campaign_info = {})
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
        
        api_name = nil
        extra_data_for_message = nil
        if properties.key?(:en) && properties[:en] == EventEnum::VWO_VARIATION_SHOWN
          api_name = ApiEnum::GET_FLAG
          if campaign_info && campaign_info.key?(:campaign_type) && (campaign_info[:campaign_type] == CampaignTypeEnum::ROLLOUT || campaign_info[:campaign_type] == CampaignTypeEnum::PERSONALIZE)
            extra_data_for_message = "feature: #{campaign_info[:feature_key]}, rule: #{campaign_info[:variation_name]}"
          elsif campaign_info
            extra_data_for_message = "feature: #{campaign_info[:feature_key]}, rule: #{campaign_info[:campaign_key]} and variation: #{campaign_info[:variation_name]}"
          end
        elsif properties.key?(:en) && properties[:en] != EventEnum::VWO_VARIATION_SHOWN
          if properties.key?(:en) && properties[:en] == EventEnum::VWO_SYNC_VISITOR_PROP
            api_name = ApiEnum::SET_ATTRIBUTE
            extra_data_for_message = api_name
          elsif properties.key?(:en) && properties[:en] != EventEnum::VWO_VARIATION_SHOWN && properties[:en] != EventEnum::VWO_DEBUGGER_EVENT && properties[:en] != EventEnum::VWO_INIT_CALLED
            api_name = ApiEnum::TRACK_EVENT
            extra_data_for_message = "event: #{properties[:en]}"
          end
        end
        begin
            if network_instance.get_client.get_should_use_threading
                network_instance.get_client.get_thread_pool.post {
                    response = network_instance.post(request)
                    if response.get_total_attempts > 0
                      debug_event_props = create_network_and_retry_debug_event(response, request.get_body, api_name, extra_data_for_message)
                      debug_event_props[:uuid] = request.get_body[:d][:visId]
                      DebuggerServiceUtil.send_debugger_event(debug_event_props)
                    end
                    if response.get_status_code == 200
                      LoggerService.log(LogLevelEnum::INFO, "NETWORK_CALL_SUCCESS", {
                        event: properties[:en],
                        endPoint: UrlEnum::EVENTS,
                        accountId: SettingsService.instance.account_id,
                        uuid: request.get_body[:d][:visId]
                      })
                    end
                    response
                }
            else
                response = network_instance.post(request)
                if response.get_status_code == 200
                    LoggerService.log(LogLevelEnum::INFO, "NETWORK_CALL_SUCCESS", {
                        event: properties[:en],
                        endPoint: UrlEnum::EVENTS,
                        accountId: SettingsService.instance.account_id,
                        uuid: request.get_body[:d][:visId]
                    })
                end
                response
            end
        rescue ResponseModel => err
            LoggerService.log(LogLevelEnum::ERROR, "NETWORK_CALL_FAILED", {
                method: extra_data_for_message,
                err: get_formatted_error_message(err.get_error)
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

        url = Constants::HOST_NAME
        if UrlUtil.get_collection_prefix && !UrlUtil.get_collection_prefix.empty?
            url = "#{url}/#{UrlUtil.get_collection_prefix}"
        end

        request = RequestModel.new(
            url,
            HttpMethodEnum::POST,
            UrlEnum::EVENTS,
            properties,
            payload,
            headers,
            Constants::HTTPS_PROTOCOL,
            nil
        )

        begin
            if network_instance.get_client.get_should_use_threading
                network_instance.get_client.get_thread_pool.post {
                    response = network_instance.post(request)
                    if response.get_status_code == 200
                        LoggerService.log(LogLevelEnum::INFO, "NETWORK_CALL_SUCCESS", {
                            event: properties[:en],
                            endPoint: UrlEnum::EVENTS,
                            accountId: SettingsService.instance.account_id,
                            uuid: request.get_body[:d][:visId]
                        })
                    end
                    response
                }
            else
                response = network_instance.post(request)
                if response.get_status_code == 200
                    LoggerService.log(LogLevelEnum::INFO, "NETWORK_CALL_SUCCESS", {
                        event: properties[:en],
                        endPoint: UrlEnum::EVENTS,
                        accountId: SettingsService.instance.account_id,
                        uuid: request.get_body[:d][:visId]
                    })
                end
                response
            end
        rescue ResponseModel => err
            if properties.key?(:en) && properties[:en] != EventEnum::VWO_DEBUGGER_EVENT
              LoggerService.log(LogLevelEnum::ERROR, "NETWORK_CALL_FAILED", {
                method: "event: #{properties[:en]}",
                err: get_formatted_error_message(err.get_error)
              })
            end
        end
    end

    # get debugger event payload
    def get_debugger_event_payload(event_props)
        user_id = SettingsService.instance.account_id.to_s + "_" + SettingsService.instance.sdk_key
        properties = _get_event_base_payload(user_id, EventEnum::VWO_DEBUGGER_EVENT, nil, nil)
        
        # check if event_props contains uuid key and should be non null and non empty string
        if event_props.key?(:uuid) && event_props[:uuid].is_a?(String) && !event_props[:uuid].empty?
            properties[:d][:msgId] = "#{event_props[:uuid]}-#{get_current_unix_timestamp_in_millis}"
            properties[:d][:visId] = event_props[:uuid]
        else
            event_props[:uuid] = properties[:d][:visId]
        end

        # check if event_props contains sessionId key 
        if event_props.key?(:sId)
            properties[:d][:sessionId] = event_props[:sId]
        else
            event_props[:sId] = properties[:d][:sessionId]
        end

        event_props[:a] = SettingsService.instance.account_id.to_s
        event_props[:product] = Constants::PRODUCT_NAME
        event_props[:sn] = Constants::SDK_NAME
        event_props[:sv] = Constants::SDK_VERSION
        event_props[:eventId] = UUIDUtil.get_random_uuid(SettingsService.instance.sdk_key)

        properties[:d][:event][:props] = {}
        properties[:d][:event][:props][:vwoMeta] = event_props
        properties
    end

    def create_network_and_retry_debug_event(response, payload, api_name, extra_data)
      begin
        category = DebugCategoryEnum::RETRY
        msg_t = Constants::NETWORK_CALL_SUCCESS_WITH_RETRIES
        msg = build_message(LoggerService.get_messages(LogLevelEnum::INFO)[msg_t], {
          extraData: extra_data,
          attempts: response.get_total_attempts,
          err: get_formatted_error_message(response.get_error)
        })
        lt = LogLevelEnum::INFO.to_s
        if response.get_status_code != 200
          category = DebugCategoryEnum::NETWORK
          msg_t = Constants::NETWORK_CALL_FAILURE_AFTER_MAX_RETRIES
          msg = build_message(LoggerService.get_messages(LogLevelEnum::ERROR)[msg_t], {
            extraData: extra_data,
            attempts: response.get_total_attempts,
            err: get_formatted_error_message(response.get_error)
          })
          lt = LogLevelEnum::ERROR.to_s
        end
        debug_event_props = {
          cg: category,
          msg_t: msg_t,
          msg: msg,
          lt: lt
        }
        if api_name
          debug_event_props[:an] = api_name
        end

        if payload && payload[:d] && payload[:d][:sessionId]
          debug_event_props[:sId] = payload[:d][:sessionId]
        else
          debug_event_props[:sId] = get_current_unix_timestamp
        end
        debug_event_props
      rescue StandardError => err
        LoggerService.log(LogLevelEnum::ERROR, "NETWORK_CALL_FAILED", {
          method: extra_data,
          err: get_formatted_error_message(err)
        })
      end
    end
  end
end
