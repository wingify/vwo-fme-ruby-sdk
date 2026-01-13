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

class ResponseModel
    attr_accessor :status_code, :error, :headers, :data, :total_attempts
  
    def initialize
      @status_code = nil
      @error = nil
      @headers = {}
      @data = nil
      @total_attempts = 0
    end
  
    def set_status_code(code)
      @status_code = code
    end
  
    def set_headers(headers)
      @headers = headers
    end
  
    def set_data(data)
      @data = data
    end

    def get_data
      @data
    end
  
    def set_error(error)
      @error = error
    end

    def get_error
      @error
    end

    def get_status_code
      @status_code
    end

    def set_total_attempts(total_attempts)
      @total_attempts = total_attempts
    end

    def get_total_attempts
      @total_attempts
    end
  end
  