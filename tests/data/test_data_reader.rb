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

require 'json'

class TestDataReader
  attr_reader :test_cases

  # Reads the test cases from a JSON file located in the specified folder.
  # The JSON file must be named "index.json".
  #
  # @param folder_path [String] The path to the folder containing the "index.json" file
  # @return [Hash, nil] A hash containing the data from the JSON file, or nil if the file doesn't exist
  def self.read_test_cases(folder_path)
    index_path = File.join(folder_path, 'index.json')
    unless File.exist?(index_path)
      raise "Test cases file not found at #{index_path}"
    end

    unless File.file?(index_path)
      raise "#{index_path} exists but is not a file"
    end

    begin
      content = File.read(index_path)
      JSON.parse(content)
    rescue JSON::ParserError => e
      raise
    rescue StandardError => e
      raise
    end
  end

  # Constructor for TestDataReader.
  # Initializes the test_cases field by reading the test cases from the specified directory.
  def initialize
    begin
      @test_cases = self.class.read_test_cases(File.join(File.dirname(__FILE__), 'test_cases'))
    rescue => e
      raise
    end
  end
end
