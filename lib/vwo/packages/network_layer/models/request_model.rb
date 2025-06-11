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

class RequestModel
    attr_accessor :url, :method, :path, :query, :timeout, :body, :headers, :scheme, :port
  
    def initialize(url, method = 'GET', path = '', query = {}, body = {}, headers = {}, scheme = 'https', port = nil)
      @url = scheme + '://' + url
      @method = method
      @path = path
      @query = query
      @timeout = 5000
      @body = body
      @headers = headers
      @scheme = scheme
      @port = port
      if !@port.nil?
        @url = @url + ':' + @port.to_s
      end
      parse_options
      self
    end
  
    def parse_options
      hostname, collection_prefix = @url.split('/')
      
      # Process body if present
      if !@body.nil?
        @headers['Content-Type'] = 'application/json'
        @headers['Content-Length'] = @body.to_json.bytesize.to_s
      end

      # Process path and query parameters
      if !@path.nil?
        query_string = @query.map { |k,v| "#{k}=#{v}" }.join('&')
        @path = query_string.empty? ? @path : "#{@path}?#{query_string}"
      end

      # Add collection prefix if present
      @path = "#{collection_prefix}#{@path}" if collection_prefix
      
      # Add timeout
      @timeout = @timeout if @timeout
    end

    def set_timeout(timeout)
      @timeout = timeout
    end

    def get_timeout
      @timeout
    end

    def set_body(body)
      @body = body
    end

    def get_body
      @body
    end

    def set_headers(headers)
      @headers = headers
    end

    def get_headers
      @headers
    end

    def set_scheme(scheme)
      @scheme = scheme
    end

    def get_scheme
      @scheme
    end

    def set_port(port)
      @port = port
    end

    def get_port
      @port
    end

    def set_path(path)
      @path = path
    end

    def get_path
      @path
    end

    def set_query(query)
      @query = query
    end

    def get_query
      @query
    end

    def set_url(url)
      @url = url
    end

    def get_url
      @url
    end

    def set_method(method)
      @method = method
    end

    def get_method
      @method
    end

    def set_query(query)
      @query = query
    end

    def get_query
      @query
    end

    def set_url(url)
      @url = url
    end

    def get_url
      @url
    end 
  end
  