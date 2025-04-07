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

# log_manager.rb
require 'securerandom'
require_relative '../logger'
require_relative 'transport_manager'
require_relative '../transports/console_transport'

class LogManager < VWOLogger
    @instance = nil

    # Use the `instance` method to initialize and get the instance
    def self.instance(config = {})
        # If an instance already exists, return it
        if @instance.nil?
        @instance = new(config)
        end
        @instance
    end
  
    def initialize(config = {})
      # Store the config in an instance variable
      @config = config
  
      # Initialize default config values inside @config
      @config[:name] ||= 'VWO Logger'
      @config[:request_id] ||= SecureRandom.uuid
      @config[:level] ||= 'ERROR'
      @config[:prefix] ||= 'VWO-SDK'
      @config[:date_time_format] ||= lambda { Time.now.iso8601 }
  
      # Initialize the transport manager with the @config hash
      @transport_manager = LogTransportManager.new(@config)
      handle_transports
    end
  
    def trace(message)
      @transport_manager.log('TRACE', message)
    end
  
    def debug(message)
      @transport_manager.log('DEBUG', message)
    end
  
    def info(message)
      @transport_manager.log('INFO', message)
    end
  
    def warn(message)
      @transport_manager.log('WARN', message)
    end
  
    def error(message)
      @transport_manager.log('ERROR', message)
    end
  
    private
  
    def handle_transports
      transports = @config[:transports] || []
  
      if transports.any?
        add_transports(transports)
      elsif @config[:transport]
        add_transport(@config[:transport])
      else
        add_transport(ConsoleTransport.new(level: @config[:level]))
      end
    end
  
    def add_transport(transport)
      @transport_manager.add_transport(transport)
    end
  
    def add_transports(transports)
      transports.each { |transport| add_transport(transport) }
    end
  end
