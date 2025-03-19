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

require_relative '../log_message_builder'

class LogTransportManager
    def initialize(config)
      @transports = []
      @config = config # This should be the global config passed to LogManager
    end
  
    def add_transport(transport)
      @transports.push(transport)
    end
  
    def should_log?(transport_level, config_level)
      target_level = log_level_to_number(transport_level)
      desired_level = log_level_to_number(config_level || @config[:level])
      target_level >= desired_level
    end
  
    def trace(message)
      log('TRACE', message)
    end
  
    def debug(message)
      log('DEBUG', message)
    end
  
    def info(message)
      log('INFO', message)
    end
  
    def warn(message)
      log('WARN', message)
    end
  
    def error(message)
      log('ERROR', message)
    end
  
    def log(level, message)
      @transports.each do |transport|
        # Pass the global config (from LogManager) to LogMessageBuilder, not the transport
        log_message_builder = LogMessageBuilder.new(@config, transport)
        formatted_message = log_message_builder.format_message(level, message)
  
        if should_log?(level, transport.level)
          if transport.respond_to?(:log) && transport.method(:log).arity == 2
            # Use custom log handler if available with correct arity
            transport.log(level, message)
          elsif transport.respond_to?(level.downcase.to_sym)
            # Use level-specific method if available
            transport.send(level.downcase.to_sym, formatted_message)
          else
            # Fallback to console_log
            transport.console_log(level, formatted_message)
          end
        end
      end
    end
  
    private
  
    def log_level_to_number(level)
      {
        'TRACE' => 0,
        'DEBUG' => 1,
        'INFO' => 2,
        'WARN' => 3,
        'ERROR' => 4
      }[level.upcase] || 0
    end
  end
  
  