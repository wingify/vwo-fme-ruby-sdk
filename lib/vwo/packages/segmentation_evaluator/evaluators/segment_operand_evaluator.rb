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
require_relative '../../../utils/data_type_util'
require_relative '../../../utils/gateway_service_util'
require_relative '../../../enums/url_enum'
require_relative '../../../services/logger_service'
require_relative '../../../models/user/context_model'
require_relative '../../../enums/log_level_enum'
class SegmentOperandEvaluator
  # Evaluates the custom variable DSL
  # @param dsl_operand_value [String] The operand value to evaluate
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
        LoggerService.log(LogLevelEnum::ERROR, "Invalid 'inList' operand format", nil)
        return false
      end

      tag_value = pre_process_tag_value(properties[operand_key])
      list_id = match[1]

      query_params_obj = { attribute: tag_value, listId: list_id }

      begin
        res = get_from_gateway_service(query_params_obj, UrlEnum::ATTRIBUTE_CHECK)
        if res.nil? || res == false || res == 'false' || (res.is_a?(Hash) && res[:status] == 0)
          return false
        end
        return res
      rescue StandardError => e
        LoggerService.log(LogLevelEnum::ERROR, "Error while fetching data: #{e}", nil)
        return false
      end

      false
    else
      tag_value = pre_process_tag_value(properties[operand_key])
      processed_values = process_values(*pre_process_operand_value(operand), tag_value)
      extract_result(processed_values[:operand_type], processed_values[:operand_value], processed_values[:tag_value])
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
    return false unless context.get_user_agent

    tag_value = CGI.unescape(context.get_user_agent)
    processed_values = process_values(*pre_process_operand_value(dsl_operand_value), tag_value)
    extract_result(processed_values[:operand_type], processed_values[:operand_value], processed_values[:tag_value])
  end

  # Pre-processes the tag value
  # @param tag_value [String] The tag value to pre-process
  # @return [String] The pre-processed tag value
  def pre_process_tag_value(tag_value)
    return '' if tag_value.nil?
    return tag_value if [true, false].include?(tag_value)

    tag_value.to_s
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
      if value.match?(SegmentOperandRegexEnum::STARTING_STAR) && value.match?(SegmentOperandRegexEnum::ENDING_STAR)
        type = SegmentOperandValueEnum::STARTING_ENDING_STAR_VALUE
        value = value.gsub(/^\*|\*$/, '')
      elsif value.match?(SegmentOperandRegexEnum::STARTING_STAR)
        type = SegmentOperandValueEnum::STARTING_STAR_VALUE
        value = value.gsub(/^\*/, '')
      elsif value.match?(SegmentOperandRegexEnum::ENDING_STAR)
        type = SegmentOperandValueEnum::ENDING_STAR_VALUE
        value = value.gsub(/\*$/, '')
      end
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
    match = operand.match(/#{regex}/)
    match ? match[1] : ''
  end

  # Processes the values from the operand and tag value
  # @param operand_type [Symbol] The type of operand
  # @param operand_value [String] The value of the operand
  # @param tag_value [String] The value of the tag
  # @return [Hash] The processed operand value and tag value
  def process_values(operand_type, operand_value, tag_value)
    # Extract values from arrays if needed
    operand_type = operand_type[1] if operand_type.is_a?(Array)
    operand_value = operand_value[1] if operand_value.is_a?(Array)
    tag_value = tag_value[1] if tag_value.is_a?(Array)

    processed_operand_value = operand_value.to_f
    processed_tag_value = tag_value.to_f

    if processed_operand_value == 0 || processed_tag_value == 0
      return { operand_type: operand_type, operand_value: operand_value, tag_value: tag_value }
    end

    { operand_type: operand_type, operand_value: processed_operand_value.to_s, tag_value: processed_tag_value.to_s }
  end

  # Extracts the result from the operand value and tag value
  # @param operand_type [Symbol] The type of operand
  # @param operand_value [String] The value of the operand
  # @param tag_value [String] The value of the tag
  # @return [Boolean] True if the operand value matches the tag value, false otherwise
  def extract_result(operand_type, operand_value, tag_value)
    case operand_type
    when SegmentOperandValueEnum::LOWER_VALUE
      operand_value.downcase == tag_value.downcase
    when SegmentOperandValueEnum::STARTING_ENDING_STAR_VALUE
      tag_value.include?(operand_value)
    when SegmentOperandValueEnum::STARTING_STAR_VALUE
      tag_value.end_with?(operand_value)
    when SegmentOperandValueEnum::ENDING_STAR_VALUE
      tag_value.start_with?(operand_value)
    when SegmentOperandValueEnum::REGEX_VALUE
      begin
        !!Regexp.new(operand_value).match?(tag_value)
      rescue StandardError
        false
      end
    when SegmentOperandValueEnum::GREATER_THAN_VALUE
      operand_value.to_f < tag_value.to_f
    when SegmentOperandValueEnum::LESS_THAN_VALUE
      operand_value.to_f > tag_value.to_f
    when SegmentOperandValueEnum::GREATER_THAN_EQUAL_TO_VALUE
      operand_value.to_f <= tag_value.to_f
    when SegmentOperandValueEnum::LESS_THAN_EQUAL_TO_VALUE
      operand_value.to_f >= tag_value.to_f
    else
      tag_value == operand_value
    end
  end
end
