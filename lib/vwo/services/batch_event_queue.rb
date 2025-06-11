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

require_relative '../utils/data_type_util'
require_relative '../services/logger_service'
require_relative '../enums/log_level_enum'
require_relative '../constants/constants'
require_relative '../packages/network_layer/manager/network_manager'
require 'concurrent'

class BatchEventsQueue
    class << self
        def instance
          @instance ||= nil
        end
    
        def configure(batch_config)
          @instance = new(batch_config)
        end
    end
    # Initializes a new batch events queue with the specified configuration
    # @param batch_config Configuration object containing:
    #   - request_time_interval: Time interval between batch requests (in seconds)
    #   - events_per_request: Maximum number of events to include in a single request
    #   - flush_callback: Callback function to execute after flushing events
    #   - dispatcher: Function to handle sending the batched events
    def initialize(batch_config)
      @queue = []
      @batch_config = batch_config
      @network_client = NetworkManager.instance.get_client
  
      if DataTypeUtil.is_number(batch_config[:request_time_interval]) && batch_config[:request_time_interval] >= 1
        @request_time_interval = batch_config[:request_time_interval]
      else
        @request_time_interval = Constants::DEFAULT_REQUEST_TIME_INTERVAL
        LoggerService.log(LogLevelEnum::INFO, "EVENT_BATCH_DEFAULTS", {
          parameter: 'request_time_interval',
          minLimit: 0,
          defaultValue: "#{@request_time_interval} seconds"
        })
      end
  
      if DataTypeUtil.is_number(batch_config[:events_per_request]) && 
         batch_config[:events_per_request] > 0 && 
         batch_config[:events_per_request] <= Constants::MAX_EVENTS_PER_REQUEST
        @events_per_request = batch_config[:events_per_request]
      elsif DataTypeUtil.is_number(batch_config[:events_per_request]) && 
            batch_config[:events_per_request] > Constants::MAX_EVENTS_PER_REQUEST
        @events_per_request = Constants::MAX_EVENTS_PER_REQUEST
        LoggerService.log(LogLevelEnum::INFO, "EVENT_BATCH_MAX_LIMIT", {
          parameter: 'events_per_request',
          maxLimit: Constants::MAX_EVENTS_PER_REQUEST.to_s
        })
      else
        @events_per_request = Constants::DEFAULT_EVENTS_PER_REQUEST
        LoggerService.log(LogLevelEnum::INFO, "EVENT_BATCH_DEFAULTS", {
          parameter: 'events_per_request',
          minLimit: 0,
          defaultValue: @events_per_request.to_s
        })
      end
  
      @flush_callback = batch_config[:flush_callback] if batch_config[:flush_callback].respond_to?(:call)
  
      @dispatcher = batch_config[:dispatcher]
      @batch_lock = Mutex.new
      @timer = nil
      create_new_batch_timer
    end
  
    # Creates a new timer thread to automatically flush events after request_time_interval
    # The timer is only created if one doesn't already exist
    def create_new_batch_timer
      return if @timer
  
      @timer = Time.now + @request_time_interval
      @thread = Thread.new { flush_when_request_times_up }
    end
  
    # Adds a new event to the queue and manages batch processing
    # If queue reaches events_per_request limit, it triggers an immediate flush
    # @param event The event to be added to the queue
    def enqueue(event)
      @queue.push(event)
  
      LoggerService.log(LogLevelEnum::INFO, "EVENT_QUEUE", {
        queueType: 'batch',
        event: event.to_json
      })

      # if the number of events in the queue is equal to the events_per_request, flush
      if @queue.length >= @events_per_request
        flush
      end
    end
  
    # Background thread function that monitors the timer
    # When the timer expires, it flushes the queue and cleans up
    def flush_when_request_times_up
      sleep(1) while @timer && Time.now < @timer
      flush
    end
  
    # Processes and sends all queued events
    # @param manual Boolean indicating if flush was triggered manually
    # Clears the queue after successful processing
    def flush(manual = false)
      @batch_lock.synchronize do
        if @queue.any?
          LoggerService.log(LogLevelEnum::DEBUG, "EVENT_BATCH_BEFORE_FLUSHING", {
            manually: manual ? 'manually' : '',
            length: @queue.length,
            accountId: @batch_config[:account_id],
            timer: manual ? 'Timer will be cleared and registered again' : ''
          })
  
          # add events to another queue
          temp_queue = @queue.dup
          @queue = []
          
          if manual
            future = Concurrent::Future.new(executor: @network_client.get_thread_pool) do
              handle_flush_response(temp_queue, manual)
            end
            future.execute
            @response = future.value
          else
            @network_client.get_thread_pool.post do
              handle_flush_response(temp_queue, manual)
            end
          end
        else
          LoggerService.log(LogLevelEnum::DEBUG, "BATCH_QUEUE_EMPTY")
          @response = {status: "success", events: []}
        end
        kill_old_thread if !manual && @thread
        clear_request_timer
        create_new_batch_timer
        @response
      end
    end
  
    private

    def handle_flush_response(temp_queue, manual)
      @response = @dispatcher.call(temp_queue, @flush_callback)
      if @response[:status] == "success"
        LoggerService.log(LogLevelEnum::INFO, "EVENT_BATCH_After_FLUSHING", {
          manually: manual ? 'manually' : '',
          length: temp_queue.length
        })
      else
        @queue.concat(temp_queue)
      end
      temp_queue = []
      @response
    end

    # Resets the request timer to nil
    def clear_request_timer
      @timer = nil
    end

    def kill_old_thread
      @old_thread&.kill
    end
end
  