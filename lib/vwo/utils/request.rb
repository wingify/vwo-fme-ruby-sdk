# Copyright 2024 Wingify Software Pvt. Ltd.
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

require 'net/http'
require 'uri'
require 'json'

module VWO
  module Utils
    # The Request class is responsible for sending HTTP GET and POST requests.
    # It uses a base URL that can be set once and then reused for all subsequent requests.
    class Request
      @@base_url = ''  # Class variable to store the base URL for requests.

      # Sets the base URL to be used for making HTTP requests.
      #
      # @param [String] url The base URL to be used for all requests.
      def self.set_base_url(url)
        @@base_url = url
      end

      # Sends an HTTP GET request to a specific endpoint using the set base URL.
      #
      # @param [String] endpoint The API endpoint to send the GET request to.
      # @return [String, nil] Returns the response body if the request is successful, or nil if it fails.
      def self.send_get_request(endpoint)
        # Combine the base URL and endpoint into a full URI.
        full_url = URI.join(@@base_url, endpoint)

        # Send the GET request and capture the response.
        response = Net::HTTP.get_response(full_url)

        # Check if the response was successful (status code 2xx).
        if response.is_a?(Net::HTTPSuccess)
          response.body  # Return the response body if successful.
        else
          # Log an error message if the request fails and return nil.
          puts "GET request failed with response code: #{response.code}"
          nil
        end
      end

      # Sends an HTTP POST request with JSON data to a specific endpoint using the set base URL.
      #
      # @param [String] endpoint The API endpoint to send the POST request to.
      # @param [Hash] data The data to be sent as the POST request body, in JSON format.
      # @return [String, nil] Returns the response body if the request is successful, or nil if it fails.
      def self.send_post_request(endpoint, data)
        # Combine the base URL and endpoint into a full URI.
        full_url = URI.join(@@base_url, endpoint)

        # Initialize a new HTTP object for the specified host and port.
        http = Net::HTTP.new(full_url.host, full_url.port)

        # Enable SSL (HTTPS) if the URL scheme is 'https'.
        http.use_ssl = true if full_url.scheme == 'https'

        # Create a new POST request object, setting the content type to JSON.
        request = Net::HTTP::Post.new(full_url, { 'Content-Type' => 'application/json' })

        # Convert the data to JSON and set it as the request body.
        request.body = data.to_json

        # Send the POST request and capture the response.
        response = http.request(request)

        # Check if the response was successful (status code 2xx).
        if response.is_a?(Net::HTTPSuccess)
          response.body  # Return the response body if successful.
        else
          # Log an error message if the request fails and return nil.
          puts "POST request failed with response code: #{response.code}"
          nil
        end
      end
    end
  end
end
