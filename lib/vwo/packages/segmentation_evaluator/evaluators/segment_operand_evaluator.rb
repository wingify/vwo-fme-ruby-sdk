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

require_relative '../utils/segment_util'
require_relative '../enums/segment_operand_value_enum'
require_relative '../enums/segment_operand_regex_enum'
require_relative '../enums/segment_operator_value_enum'
require_relative '../../../utils/data_type_util'
require_relative '../../../utils/gateway_service_util'
require_relative '../../../enums/url_enum'
require_relative '../../../services/logger_service'
require_relative '../../../models/user/context_model'
require_relative '../../../enums/log_level_enum'
require_relative '../../../enums/api_enum'

# SegmentOperandEvaluator class provides methods to evaluate different types of DSL (Domain Specific Language)
# expressions based on the segment conditions defined for custom variables, user IDs, and user agents.
class SegmentOperandEvaluator
  # Regex pattern to check if a string contains non-numeric characters (except decimal point)
  NON_NUMERIC_PATTERN = /[^0-9.]/

  # Evaluates the custom variable DSL
  # @param dsl_operand_value [Hash] The operand value to evaluate
  # @param properties [Hash] The properties to evaluate the operand against
  # @return [Boolean] True if the operand value matches the tag value, false otherwise
  def evaluate_custom_variable_dsl(dsl_operand_value, properties)
    key_value = get_key_value(dsl_operand_value)
    return false unless key_value

    operand_key = key_value[:key].to_sym
    operand = key_value[:value]

    return false unless properties.key?(operand_key)

    if operand.include?('inlist')
      match = operand.match(/inlist\(([^)]+)\)/)
      unless match
        LoggerService.log(LogLevelEnum::ERROR, "INVALID_ATTRIBUTE_LIST_FORMAT", { an: ApiEnum::GET_FLAG, sId: @context.get_session_id, uuid: @context.get_uuid})
        return false
      end

      tag_value = properties[operand_key]
      attribute_value = pre_process_tag_value(tag_value)
      list_id = match[1]

      query_params_obj = { attribute: attribute_value, listId: list_id }

      begin
        res = get_from_gateway_service(query_params_obj, UrlEnum::ATTRIBUTE_CHECK)
        if res.nil? || res == false || res == 'false' || (res.is_a?(Hash) && res[:status] == 0)
          return false
        end
        return res
      rescue StandardError => e
        LoggerService.log(LogLevelEnum::ERROR, "ERROR_FETCHING_DATA_FROM_GATEWAY", { err: e.message, an: ApiEnum::GET_FLAG, sId: @context.get_session_id, uuid: @context.get_uuid})
        return false
      end

      false
    else
      tag_value = properties[operand_key]
      tag_value = pre_process_tag_value(tag_value)
      processed_operand = pre_process_operand_value(operand)
      processed_values = process_values(processed_operand[:operand_value], tag_value)
      tag_value = processed_values[:tag_value]
      extract_result(processed_operand[:operand_type], processed_values[:operand_value], tag_value)
    end
  end

  # Evaluates the user DSL
  # @param dsl_operand_value [String] The operand value to evaluate
  # @param properties [Hash] The properties to evaluate the operand against
  # @return [Boolean] True if the operand value matches the tag value, false otherwise
  def evaluate_user_dsl(dsl_operand_value, properties)
    users = dsl_operand_value.split(',')
    users.any? { |user| user.strip == properties["_vwoUserId"].to_s }
  end

  # Evaluates the user agent DSL
  # @param dsl_operand_value [String] The operand value to evaluate
  # @param context [ContextModel] The context to evaluate the operand against
  # @return [Boolean] True if the operand value matches the tag value, false otherwise
  def evaluate_user_agent_dsl(dsl_operand_value, context)
    operand = dsl_operand_value
    unless context.get_user_agent
      LoggerService.log(LogLevelEnum::INFO, 'To Evaluate UserAgent segmentation, please provide userAgent in context', nil)
      return false
    end

    tag_value = CGI.unescape(context.get_user_agent)
    processed_operand = pre_process_operand_value(operand)
    processed_values = process_values(processed_operand[:operand_value], tag_value)
    tag_value = processed_values[:tag_value]
    extract_result(processed_operand[:operand_type], processed_values[:operand_value], tag_value)
  end

  # Evaluates a given string tag value against a DSL operand value.
  # @param dsl_operand_value [String] The DSL operand string (e.g., "contains(\"value\")").
  # @param context [ContextModel] The context object containing the value to evaluate.
  # @param operand_type [String] The type of operand being evaluated (ip_address, browser_version, os_version).
  # @return [Boolean] True if tag value matches DSL operand criteria, false otherwise.
  def evaluate_string_operand_dsl(dsl_operand_value, context, operand_type)
    operand = dsl_operand_value.to_s

    # Determine the tag value based on operand type
    tag_value = get_tag_value_for_operand_type(context, operand_type)

    if tag_value.nil?
      log_missing_context_error(operand_type)
      return false
    end

    operand_type_and_value = pre_process_operand_value(operand)
    processed_values = process_values(operand_type_and_value[:operand_value], tag_value, operand_type)
    processed_tag_value = processed_values[:tag_value]

    extract_result(
      operand_type_and_value[:operand_type],
      processed_values[:operand_value].to_s.strip.gsub(/"/, ''),
      processed_tag_value
    )
  end

  # Evaluates IP address DSL expression.
  # @param dsl_operand_value [String] The DSL expression for the IP address.
  # @param context [ContextModel] The context object containing the IP address.
  # @return [Boolean] True if the IP address matches the DSL condition, otherwise false.
  def evaluate_ip_dsl(dsl_operand_value, context)
    evaluate_string_operand_dsl(dsl_operand_value, context, SegmentOperatorValueEnum::IP)
  end

  # Evaluates browser version DSL expression.
  # @param dsl_operand_value [String] The DSL expression for the browser version.
  # @param context [ContextModel] The context object containing the user agent info.
  # @return [Boolean] True if the browser version matches the DSL condition, otherwise false.
  def evaluate_browser_version_dsl(dsl_operand_value, context)
    evaluate_string_operand_dsl(dsl_operand_value, context, SegmentOperatorValueEnum::BROWSER_VERSION)
  end

  # Evaluates OS version DSL expression.
  # @param dsl_operand_value [String] The DSL expression for the OS version.
  # @param context [ContextModel] The context object containing the user agent info.
  # @return [Boolean] True if the OS version matches the DSL condition, otherwise false.
  def evaluate_os_version_dsl(dsl_operand_value, context)
    evaluate_string_operand_dsl(dsl_operand_value, context, SegmentOperatorValueEnum::OS_VERSION)
  end

  # Gets the appropriate tag value based on the operand type.
  # @param context [ContextModel] The context object.
  # @param operand_type [String] The type of operand.
  # @return [String, nil] The tag value or nil if not available.
  def get_tag_value_for_operand_type(context, operand_type)
    case operand_type
    when SegmentOperatorValueEnum::IP
      context.get_ip_address
    when SegmentOperatorValueEnum::BROWSER_VERSION
      get_browser_version_from_context(context)
    else
      # Default works for OS version
      get_os_version_from_context(context)
    end
  end

  # Gets browser version from context.
  # @param context [ContextModel] The context object.
  # @return [String, nil] The browser version or nil if not available.
  def get_browser_version_from_context(context)
    user_agent = context.get_vwo&.get_ua_info
    return nil unless user_agent && user_agent.is_a?(Hash) && !user_agent.empty?

    # Assuming UserAgent dictionary contains browser_version
    if user_agent.key?('browser_version')
      return user_agent['browser_version']&.to_s
    end
    nil
  end

  # Gets OS version from context.
  # @param context [ContextModel] The context object.
  # @return [String, nil] The OS version or nil if not available.
  def get_os_version_from_context(context)
    user_agent = context.get_vwo&.get_ua_info
    return nil unless user_agent && user_agent.is_a?(Hash) && !user_agent.empty?

    # Assuming UserAgent dictionary contains os_version
    if user_agent.key?('os_version')
      return user_agent['os_version']&.to_s
    end
    nil
  end

  # Logs appropriate error message for missing context.
  # @param operand_type [String] The type of operand.
  def log_missing_context_error(operand_type)
    case operand_type
    when SegmentOperatorValueEnum::IP
      LoggerService.log(LogLevelEnum::INFO, 'To evaluate IP segmentation, please provide ipAddress in context', nil)
    when SegmentOperatorValueEnum::BROWSER_VERSION
      LoggerService.log(LogLevelEnum::INFO, 'To evaluate browser version segmentation, please provide userAgent in context', nil)
    else
      LoggerService.log(LogLevelEnum::INFO, 'To evaluate OS version segmentation, please provide userAgent in context', nil)
    end
  end

  # Pre-processes the tag value to ensure it is in the correct format for evaluation.
  # @param tag_value [Any] The value to be processed.
  # @return [String, Boolean] The processed tag value, either as a string or a boolean.
  def pre_process_tag_value(tag_value)
    # Default to empty string if undefined
    if tag_value.nil?
      tag_value = ''
    end
    # Convert boolean values to boolean type
    if DataTypeUtil.is_boolean(tag_value)
      tag_value = tag_value ? true : false
    end
    # Convert all non-null values to string
    unless tag_value.nil?
      tag_value = tag_value.to_s
    end
    tag_value
  end

  # Pre-processes the operand value
  # @param operand [String] The operand to pre-process
  # @return [Hash] The pre-processed operand value
  def pre_process_operand_value(operand)
    case operand
    when /#{SegmentOperandRegexEnum::LOWER_MATCH}/
      { operand_type: SegmentOperandValueEnum::LOWER_VALUE, operand_value: extract_operand_value(operand, SegmentOperandRegexEnum::LOWER_MATCH) }
    when /#{SegmentOperandRegexEnum::WILDCARD_MATCH}/
      value = extract_operand_value(operand, SegmentOperandRegexEnum::WILDCARD_MATCH)
      starting_star = match_with_regex(value, SegmentOperandRegexEnum::STARTING_STAR)
      ending_star = match_with_regex(value, SegmentOperandRegexEnum::ENDING_STAR)
      
      # Determine specific wildcard type
      if starting_star && ending_star
        type = SegmentOperandValueEnum::STARTING_ENDING_STAR_VALUE
      elsif starting_star
        type = SegmentOperandValueEnum::STARTING_STAR_VALUE
      elsif ending_star
        type = SegmentOperandValueEnum::ENDING_STAR_VALUE
      end
      
      # Remove wildcard characters from the operand value
      value = value
        .gsub(Regexp.new(SegmentOperandRegexEnum::STARTING_STAR), '')
        .gsub(Regexp.new(SegmentOperandRegexEnum::ENDING_STAR), '')
      
      { operand_type: type, operand_value: value }
    when /#{SegmentOperandRegexEnum::REGEX_MATCH}/
      { operand_type: SegmentOperandValueEnum::REGEX_VALUE, operand_value: extract_operand_value(operand, SegmentOperandRegexEnum::REGEX_MATCH) }
    when /#{SegmentOperandRegexEnum::GREATER_THAN_MATCH}/
      { operand_type: SegmentOperandValueEnum::GREATER_THAN_VALUE, operand_value: extract_operand_value(operand, SegmentOperandRegexEnum::GREATER_THAN_MATCH) }
    when /#{SegmentOperandRegexEnum::LESS_THAN_MATCH}/
      { operand_type: SegmentOperandValueEnum::LESS_THAN_VALUE, operand_value: extract_operand_value(operand, SegmentOperandRegexEnum::LESS_THAN_MATCH) }
    when /#{SegmentOperandRegexEnum::GREATER_THAN_EQUAL_TO_MATCH}/
      { operand_type: SegmentOperandValueEnum::GREATER_THAN_EQUAL_TO_VALUE, operand_value: extract_operand_value(operand, SegmentOperandRegexEnum::GREATER_THAN_EQUAL_TO_MATCH) }
    when /#{SegmentOperandRegexEnum::LESS_THAN_EQUAL_TO_MATCH}/
      { operand_type: SegmentOperandValueEnum::LESS_THAN_EQUAL_TO_VALUE, operand_value: extract_operand_value(operand, SegmentOperandRegexEnum::LESS_THAN_EQUAL_TO_MATCH) }
    else
      { operand_type: SegmentOperandValueEnum::EQUAL_VALUE, operand_value: operand }
    end
  end

  # Extracts the operand value from the operand
  # @param operand [String] The operand to extract the value from
  # @param regex [String] The regex to match the operand against
  # @return [String] The extracted operand value
  def extract_operand_value(operand, regex)
    match_result = match_with_regex(operand, regex)
    match_result && match_result[1] ? match_result[1] : ''
  end

  # Processes numeric values from operand and tag values, converting them to strings.
  # @param operand_value [Any] The operand value to process.
  # @param tag_value [Any] The tag value to process.
  # @param operand_type [String] The type of operand being evaluated (optional).
  # @return [Hash] An object containing the processed operand and tag values as strings.
  def process_values(operand_value, tag_value, operand_type = nil)
    if [SegmentOperatorValueEnum::IP, SegmentOperatorValueEnum::BROWSER_VERSION, SegmentOperatorValueEnum::OS_VERSION].include?(operand_type)
      return {
        operand_value: operand_value,
        tag_value: tag_value
      }
    end

    # Convert operand and tag values to floats
    if NON_NUMERIC_PATTERN.match?(tag_value.to_s)
      return {
        operand_value: operand_value,
        tag_value: tag_value
      }
    end

    processed_operand_value = operand_value.to_f
    processed_tag_value = tag_value.to_f

    # Return original values if conversion fails
    if processed_operand_value == 0 && operand_value.to_s != '0' && operand_value.to_s != '0.0'
      return {
        operand_value: operand_value,
        tag_value: tag_value
      }
    end

    if processed_tag_value == 0 && tag_value.to_s != '0' && tag_value.to_s != '0.0'
      return {
        operand_value: operand_value,
        tag_value: tag_value
      }
    end

    # Convert numeric values back to strings
    {
      operand_value: processed_operand_value.to_s,
      tag_value: processed_tag_value.to_s
    }
  end

  # Extracts the result from the operand value and tag value
  # @param operand_type [Symbol] The type of operand
  # @param operand_value [String] The value of the operand
  # @param tag_value [String] The value of the tag
  # @return [Boolean] True if the operand value matches the tag value, false otherwise
  def extract_result(operand_type, operand_value, tag_value)
    result = false

    return false if tag_value.nil?

    # Ensure operand_value and tag_value are strings
    operand_value_str = operand_value.to_s
    tag_value_str = tag_value.to_s

    case operand_type
    when SegmentOperandValueEnum::LOWER_VALUE
      result = operand_value_str.downcase == tag_value_str.downcase
    when SegmentOperandValueEnum::STARTING_ENDING_STAR_VALUE
      result = tag_value_str.include?(operand_value_str)
    when SegmentOperandValueEnum::STARTING_STAR_VALUE
      result = tag_value_str.end_with?(operand_value_str)
    when SegmentOperandValueEnum::ENDING_STAR_VALUE
      result = tag_value_str.start_with?(operand_value_str)
    when SegmentOperandValueEnum::REGEX_VALUE
      begin
        pattern = Regexp.new(operand_value_str)
        result = pattern.match?(tag_value_str)
      rescue StandardError
        result = false
      end
    when SegmentOperandValueEnum::GREATER_THAN_VALUE
      result = compare_versions(tag_value_str, operand_value_str) > 0
    when SegmentOperandValueEnum::GREATER_THAN_EQUAL_TO_VALUE
      result = compare_versions(tag_value_str, operand_value_str) >= 0
    when SegmentOperandValueEnum::LESS_THAN_VALUE
      result = compare_versions(tag_value_str, operand_value_str) < 0
    when SegmentOperandValueEnum::LESS_THAN_EQUAL_TO_VALUE
      result = compare_versions(tag_value_str, operand_value_str) <= 0
    else
      # For version-like strings, use version comparison; otherwise use string comparison
      if version_string?(tag_value_str) && version_string?(operand_value_str)
        result = compare_versions(tag_value_str, operand_value_str) == 0
      else
        result = tag_value_str == operand_value_str
      end
    end

    result
  end

  # Checks if a string appears to be a version string (contains only digits and dots).
  # @param str [String] The string to check.
  # @return [Boolean] True if the string appears to be a version string.
  def version_string?(str)
    /^(\d+\.)*\d+$/.match?(str)
  end

  # Compares two version strings using semantic versioning rules.
  # Supports formats like "1.2.3", "1.0", "2.1.4.5", etc.
  # @param version1 [String] First version string.
  # @param version2 [String] Second version string.
  # @return [Integer] -1 if version1 < version2, 0 if equal, 1 if version1 > version2.
  def compare_versions(version1, version2)
    # Split versions by dots and convert to integers
    parts1 = version1.split('.').map { |part| part.match?(/^\d+$/) ? part.to_i : 0 }
    parts2 = version2.split('.').map { |part| part.match?(/^\d+$/) ? part.to_i : 0 }

    # Find the maximum length to handle different version formats
    max_length = [parts1.length, parts2.length].max

    (0...max_length).each do |i|
      part1 = i < parts1.length ? parts1[i] : 0
      part2 = i < parts2.length ? parts2[i] : 0

      if part1 < part2
        return -1
      elsif part1 > part2
        return 1
      end
    end

    0 # Versions are equal
  end
end
