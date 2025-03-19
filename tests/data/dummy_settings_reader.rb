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

class DummySettingsReader
  attr_reader :settings_map

  def initialize
    # current directory
    current_dir = File.dirname(__FILE__)
    @settings_map = read_json_files_from_folder(File.join(current_dir, 'settings'))
  end

  private

  # Reads JSON files from a specified folder and returns a hash where the keys are the filenames
  # (without extensions) and the values are the contents of the files as strings.
  #
  # @param folder_path [String] The path to the folder containing the JSON files
  # @return [Hash] A hash with filenames (without extensions) as keys and file contents as values
  def read_json_files_from_folder(folder_path)
    json_files_map = {}
    
    Dir.glob(File.join(folder_path, '*.json')).each do |file_path|
      content = File.read(file_path)
      filename_without_extension = File.basename(file_path, '.json')
      json_files_map[filename_without_extension] = content
    rescue StandardError => e
      puts e.message
    end

    json_files_map
  end
end
