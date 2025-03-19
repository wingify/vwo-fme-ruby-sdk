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
require_relative '../vwo_client'
require_relative '../packages/logger/core/log_manager'
require_relative '../enums/log_level_enum'
require_relative '../utils/log_message_util'

class LoggerService
  class << self
    attr_accessor :debug_messages, :info_messages, :error_messages, :warning_messages
  end

  def self.log(level, key = nil, map = {})
    log_manager = LogManager.instance

    if key && map
      message = build_message(get_messages(level)[key], map)
    else
      message = key # key acts as the message when no map is provided
    end

    case level
    when LogLevelEnum::DEBUG
      log_manager.debug(message)
    when LogLevelEnum::INFO
      log_manager.info(message)
    when LogLevelEnum::WARN
      log_manager.warn(message)
    else
      log_manager.error(message)
    end
  end

  def initialize(config = {})
    # Initialize the LogManager
    LogManager.instance(config)

    # Read the log files and set class variables
    self.class.debug_messages = read_log_files('debug_messages.json')
    self.class.info_messages = read_log_files('info_messages.json')
    self.class.error_messages = read_log_files('error_messages.json')
    self.class.warning_messages = read_log_files('warn_messages.json')
  end

  private

  def read_log_files(file_name)
    begin
      # Use absolute path resolution from the project root
      file_path = File.join(File.expand_path('../../resources', __dir__), file_name)
      return JSON.parse(File.read(file_path))
    rescue StandardError => e
      puts "Error reading log file #{file_name}: #{e.message}"
      return {}
    end
  end

  def self.get_messages(level)
    case level
    when LogLevelEnum::DEBUG
      @debug_messages
    when LogLevelEnum::INFO
      @info_messages
    when LogLevelEnum::WARN
      @warning_messages
    else
      @error_messages
    end
  end
end
