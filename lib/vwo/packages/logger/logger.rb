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

# logger.rb
class VWOLogger
    # Abstract method definitions for logging at different levels
    def trace(message)
      raise NotImplementedError, "You must implement the trace method"
    end
  
    def debug(message)
      raise NotImplementedError, "You must implement the debug method"
    end
  
    def info(message)
      raise NotImplementedError, "You must implement the info method"
    end
  
    def warn(message)
      raise NotImplementedError, "You must implement the warn method"
    end
  
    def error(message)
      raise NotImplementedError, "You must implement the error method"
    end
  end
  