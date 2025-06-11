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

class LogMessageBuilder
    ANSI_COLOR_ENUM = {
      bold: "\x1b[1m",
      cyan: "\x1b[36m",
      green: "\x1b[32m",
      lightblue: "\x1b[94m",
      red: "\x1b[31m",
      reset: "\x1b[0m",
      white: "\x1b[30m",
      yellow: "\x1b[33m"
    }
  
    LOG_LEVEL_COLOR = {
      'TRACE' => ANSI_COLOR_ENUM[:white],
      'DEBUG' => ANSI_COLOR_ENUM[:lightblue],
      'INFO' => ANSI_COLOR_ENUM[:cyan],
      'WARN' => ANSI_COLOR_ENUM[:yellow],
      'ERROR' => ANSI_COLOR_ENUM[:red]
    }
  
    def initialize(logger_config, transport_config)
      @logger_config = logger_config
      @transport_config = transport_config
  
      # Access the values directly from transport_config if available.
      @prefix = transport_config.instance_variable_get(:@prefix) || logger_config[:prefix] || ''
      @date_time_format = transport_config.respond_to?(:date_time_format) ? transport_config.date_time_format : logger_config[:date_time_format] || lambda { Time.now.iso8601 }
    end
  
    def format_message(level, message)
      "[#{get_formatted_level(level)}]: #{get_formatted_prefix(@prefix)} #{get_formatted_date_time} #{message}"
    end
  
    private
  
    def get_formatted_prefix(prefix)
      if @logger_config[:is_ansi_color_enabled]
        "#{ANSI_COLOR_ENUM[:bold]}#{ANSI_COLOR_ENUM[:green]}#{prefix}#{ANSI_COLOR_ENUM[:reset]}"
      else
        prefix
      end
    end
  
    def get_formatted_level(level)
      color = LOG_LEVEL_COLOR[level.upcase] || ''
      level_string = level.upcase
      return "#{color}#{level_string}#{ANSI_COLOR_ENUM[:reset]}" if @logger_config[:is_ansi_color_enabled]
  
      level_string
    end
  
    def get_formatted_date_time
      @date_time_format.call
    end
  end
  