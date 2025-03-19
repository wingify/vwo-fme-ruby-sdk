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

class GlobalRequestModel
    attr_accessor :url, :timeout, :query, :body, :headers, :is_development_mode
  
    # Constructs an instance of the GlobalRequestModel.
    # @param url [String] The base URL of the HTTP request.
    # @param query [Hash] Query parameters as a record of key-value pairs.
    # @param body [Hash] Body of the request as a record of key-value pairs.
    # @param headers [Hash] HTTP headers as a record of key-value pairs.
    def initialize(url, query, body, headers)
      @url = url
      @query = query
      @body = body
      @headers = headers
      @timeout = 3000 # Default timeout in milliseconds
      @is_development_mode = nil # Flag to indicate if the request is in development mode
    end
  
    # Sets the query parameters for the HTTP request.
    # @param query [Hash] A record of key-value pairs representing the query parameters.
    def set_query(query)
      @query = query
    end
  
    # Retrieves the query parameters of the HTTP request.
    # @returns [Hash] A record of key-value pairs representing the query parameters.
    def get_query
      @query
    end
  
    # Sets the body of the HTTP request.
    # @param body [Hash] A record of key-value pairs representing the body content.
    def set_body(body)
      @body = body
    end
  
    # Retrieves the body of the HTTP request.
    # @returns [Hash] A record of key-value pairs representing the body content.
    def get_body
      @body
    end
  
    # Sets the base URL of the HTTP request.
    # @param url [String] The base URL as a string.
    def set_base_url(url)
      @url = url
    end
  
    # Retrieves the base URL of the HTTP request.
    # @returns [String] The base URL as a string.
    def get_base_url
      @url
    end
  
    # Sets the timeout duration for the HTTP request.
    # @param timeout [Integer] Timeout in milliseconds.
    def set_timeout(timeout)
      @timeout = timeout
    end
  
    # Retrieves the timeout duration of the HTTP request.
    # @returns [Integer] Timeout in milliseconds.
    def get_timeout
      @timeout
    end
  
    # Sets the HTTP headers for the request.
    # @param headers [Hash] A record of key-value pairs representing the HTTP headers.
    def set_headers(headers)
      @headers = headers
    end
  
    # Retrieves the HTTP headers of the request.
    # @returns [Hash] A record of key-value pairs representing the HTTP headers.
    def get_headers
      @headers
    end
  
    # Sets the development mode status for the request.
    # @param is_development_mode [Boolean] Boolean flag indicating if the request is in development mode.
    def set_development_mode(is_development_mode)
      @is_development_mode = is_development_mode
    end
  
    # Retrieves the development mode status of the request.
    # @returns [Boolean] Boolean indicating if the request is in development mode.
    def get_development_mode
      @is_development_mode
    end
  end
  
  