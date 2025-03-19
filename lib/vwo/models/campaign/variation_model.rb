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

require_relative 'variable_model'

class VariationModel
  attr_accessor :id, :key, :rule_key, :weight, :segments, :start_range_variation,
                :end_range_variation, :variables, :variations, :type, :salt

  def initialize
    @id = nil
    @key = ''
    @rule_key = ''
    @weight = 0
    @start_range_variation = 0
    @end_range_variation = 0
    @variables = []
    @variations = []
    @segments = {}
    @type = ''
    @salt = ''
  end

  # Creates a model instance from a hash (dictionary)
  def model_from_dictionary(variation)
    if variation.is_a?(Hash)
      @id = variation["id"]
      @key = variation["key"] || variation["name"]
      @weight = variation["weight"]
      @rule_key = variation["ruleKey"]
      @salt = variation["salt"]
      @type = variation["type"]
      @start_range_variation = variation["start_range_variation"]
      @end_range_variation = variation["end_range_variation"]
      @segments = variation["segments"] if variation["segments"]

      @variables = process_variables(variation["variables"])
      @variations = process_variations(variation["variations"])
    elsif variation.is_a?(VariationModel)
      @id = variation.id
      @key = variation.key
      @weight = variation.weight
      @rule_key = variation.rule_key
      @salt = variation.salt
      @type = variation.type
      @start_range_variation = variation.start_range_variation
      @end_range_variation = variation.end_range_variation
      @segments = variation.segments
      @variables = variation.variables
      @variations = variation.variations
    else
      @id = variation.id
      @key = variation.key
      @rule_key = variation.rule_key
      @salt = variation.salt
      @type = variation.type
      @segments = variation.segments
      @variations = variation.variations
    end
    self
  end

  # Process variables list
  def process_variables(variable_list)
    return [] unless variable_list.is_a?(Array)
    variable_list.map { |variable| VariableModel.new.model_from_dictionary(variable) }
  end

  # Process variations list
  def process_variations(variation_list)
    return [] unless variation_list.is_a?(Array)
    variation_list.map { |variation| VariationModel.new.model_from_dictionary(variation) }
  end

  def get_id
    @id
  end

  def get_key
    @key
  end

  def get_rule_key
    @rule_key
  end

  def get_weight
    @weight
  end

  def get_start_range_variation
    @start_range_variation
  end

  def set_start_range(start_range_variation)
    @start_range_variation = start_range_variation
  end

  def get_end_range_variation
    @end_range_variation
  end

  def set_end_range(end_range_variation)
    @end_range_variation = end_range_variation
  end

  def get_variables
    @variables
  end

  def get_variations
    @variations
  end

  def get_segments
    @segments
  end

  def get_type
    @type
  end

  def get_salt
    @salt
  end
end