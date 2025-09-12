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

require 'json'
require_relative '../../../decorators/storage_decorator'
require_relative '../../../models/settings/settings_model'
require_relative '../../../models/user/context_model'
require_relative '../../../models/campaign/feature_model'
require_relative '../../../services/storage_service'
require_relative '../../../services/logger_service'
require_relative '../enums/segment_operator_value_enum'
require_relative '../core/segmentation_manager'
require_relative '../utils/segment_util'
require_relative './segment_operand_evaluator'
require_relative '../../../enums/log_level_enum'
class SegmentEvaluator
  attr_accessor :context, :settings, :feature

  def initialize(context = nil, settings = nil, feature = nil)
    @context = context
    @settings = settings
    @feature = feature
  end

  # Validates if the segmentation defined in the DSL is applicable based on the provided properties.
  # @param dsl [Hash] The DSL node to evaluate
  # @param properties [Hash] The properties to evaluate the DSL against
  # @return [Boolean] True if the segmentation is valid, false otherwise
  def is_segmentation_valid(dsl, properties)
    key_value = get_key_value(dsl)
    return false unless key_value

    operator = key_value[:key]
    sub_dsl = key_value[:value]

    case operator
    when SegmentOperatorValueEnum::NOT
      !is_segmentation_valid(sub_dsl, properties)
    when SegmentOperatorValueEnum::AND
      every(sub_dsl, properties)
    when SegmentOperatorValueEnum::OR
      some(sub_dsl, properties)
    when SegmentOperatorValueEnum::CUSTOM_VARIABLE
      SegmentOperandEvaluator.new.evaluate_custom_variable_dsl(sub_dsl, properties)
    when SegmentOperatorValueEnum::USER
      SegmentOperandEvaluator.new.evaluate_user_dsl(sub_dsl, properties)
    when SegmentOperatorValueEnum::UA
      SegmentOperandEvaluator.new.evaluate_user_agent_dsl(sub_dsl, @context)
    when SegmentOperatorValueEnum::IP
      SegmentOperandEvaluator.new.evaluate_string_operand_dsl(sub_dsl, @context, SegmentOperatorValueEnum::IP)
    when SegmentOperatorValueEnum::BROWSER_VERSION
      SegmentOperandEvaluator.new.evaluate_string_operand_dsl(sub_dsl, @context, SegmentOperatorValueEnum::BROWSER_VERSION)
    when SegmentOperatorValueEnum::OS_VERSION
      SegmentOperandEvaluator.new.evaluate_string_operand_dsl(sub_dsl, @context, SegmentOperatorValueEnum::OS_VERSION)
    else
      false
    end
  end

  # Evaluates if any of the DSL nodes are valid using the OR logic.
  # @param dsl_nodes [Array<Hash>] The DSL nodes to evaluate
  # @param custom_variables [Hash] The custom variables
  # @return [Boolean] True if any of the DSL nodes are valid, false otherwise
  def some(dsl_nodes, custom_variables)
    ua_parser_map = {}
    key_count = 0
    is_ua_parser = false

    dsl_nodes.each do |dsl|
      dsl.each do |key, value|
        if [SegmentOperatorValueEnum::OPERATING_SYSTEM, SegmentOperatorValueEnum::BROWSER_AGENT,
            SegmentOperatorValueEnum::DEVICE_TYPE, SegmentOperatorValueEnum::DEVICE].include?(key)
          is_ua_parser = true
          ua_parser_map[key] ||= []
          ua_parser_map[key] += Array(value).map(&:to_s)
          key_count += 1
        end

        if key == SegmentOperatorValueEnum::FEATURE_ID
          feature_id_object = dsl[key]
          feature_id_key = feature_id_object.keys.first
          feature_id_value = feature_id_object[feature_id_key]

          if %w[on off].include?(feature_id_value)
            feature = @settings.get_features.find { |f| f.get_id == feature_id_key.to_i }
            if feature
              feature_key = feature.get_key
              result = check_in_user_storage(@settings, feature_key, @context)
              return !result if feature_id_value == 'off'
              return result
            else
              LoggerService.log(LogLevelEnum::ERROR, "Feature not found with featureIdKey: #{feature_id_key}", nil)
              return nil
            end
          end
        end
      end

      return check_user_agent_parser(ua_parser_map) if is_ua_parser && key_count == dsl_nodes.length
      return true if is_segmentation_valid(dsl, custom_variables)
    end

    false
  end

  # Evaluates all DSL nodes using the AND logic.
  # @param dsl_nodes [Array<Hash>] The DSL nodes to evaluate
  # @param custom_variables [Hash] The custom variables
  # @return [Boolean] True if all DSL nodes are valid, false otherwise
  def every(dsl_nodes, custom_variables)
    location_map = {}
    dsl_nodes.each do |dsl|
      if dsl.keys.any? { |key| [SegmentOperatorValueEnum::COUNTRY, SegmentOperatorValueEnum::REGION,
                                SegmentOperatorValueEnum::CITY].include?(key) }
        add_location_values_to_map(dsl, location_map)
        return check_location_pre_segmentation(location_map) if location_map.keys.length == dsl_nodes.length
        next
      end
      return false unless is_segmentation_valid(dsl, custom_variables)
    end
    true
  end

  # Adds the location values to the map
  # @param dsl [Hash] The DSL node
  # @param location_map [Hash] The location map
  def add_location_values_to_map(dsl, location_map)
    location_map[SegmentOperatorValueEnum::COUNTRY] = dsl[SegmentOperatorValueEnum::COUNTRY] if dsl.key?(SegmentOperatorValueEnum::COUNTRY)
    location_map[SegmentOperatorValueEnum::REGION] = dsl[SegmentOperatorValueEnum::REGION] if dsl.key?(SegmentOperatorValueEnum::REGION)
    location_map[SegmentOperatorValueEnum::CITY] = dsl[SegmentOperatorValueEnum::CITY] if dsl.key?(SegmentOperatorValueEnum::CITY)
  end

  # Checks if the location pre-segmentation is valid
  # @param location_map [Hash] The location map
  # @return [Boolean] True if the location pre-segmentation is valid, false otherwise
  def check_location_pre_segmentation(location_map)
    unless @context&.get_ip_address
      LoggerService.log(LogLevelEnum::ERROR, 'To evaluate location pre Segment, please pass ipAddress in context object', nil)
      return false
    end
    
    unless @context&.get_vwo&.get_location
      return false
    end

    values_match(location_map, @context.get_vwo.get_location)
  end

  # Checks if the user agent parser is valid
  # @param ua_parser_map [Hash] The user agent parser map
  # @return [Boolean] True if the user agent parser is valid, false otherwise
  def check_user_agent_parser(ua_parser_map)
    unless @context&.get_user_agent
      LoggerService.log(LogLevelEnum::ERROR, 'To evaluate user agent related segments, please pass userAgent in context object', nil)
      return false
    end

    unless @context&.get_vwo&.get_ua_info
      return false
    end

    check_value_present(ua_parser_map, @context.get_vwo.get_ua_info)
  end

  # Checks if the feature key is present in the user's storage
  # @param settings [SettingsModel] The settings for the VWO instance
  # @param feature_key [String] The key of the feature to check
  # @param context [ContextModel] The context for the evaluation
  # @return [Boolean] True if the feature key is present in the user's storage, false otherwise
  def check_in_user_storage(settings, feature_key, context)
    storage_service = StorageService.new
    stored_data = StorageDecorator.new.get_feature_from_storage(feature_key, context, storage_service)
    stored_data.is_a?(Hash) && !stored_data.empty?
  end

  # Checks if the expected values are present in the actual values
  # @param expected_map [Hash] The expected values
  # @param actual_map [Hash] The actual values
  # @return [Boolean] True if the expected values are present in the actual values, false otherwise
  def check_value_present(expected_map, actual_map)
    actual_map.each do |key, actual_value|
      next unless expected_map.key?(key)

      expected_values = expected_map[key].map(&:downcase)

      return true if expected_values.any? { |val| val.start_with?('wildcard(') && val.end_with?(')') && actual_value.match?(Regexp.new(val[9..-2].gsub('*', '.*'), Regexp::IGNORECASE)) }
      return true if expected_values.include?(actual_value.downcase)
    end
    false
  end

  # Checks if the expected location values match the user's location
  # @param expected_location_map [Hash] The expected location values
  # @param user_location [Hash] The user's location values
  # @return [Boolean] True if the expected location values match the user's location, false otherwise
  def values_match(expected_location_map, user_location)
    expected_location_map.all? { |key, value| normalize_value(value) == normalize_value(user_location[key]) }
  end

  def normalize_value(value)
    return nil if value.nil?

    value.to_s.gsub(/^"|"$/, '').strip
  end
end
