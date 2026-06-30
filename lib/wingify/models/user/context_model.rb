# Copyright 2024-2026 Wingify Software Pvt. Ltd.
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

require_relative './context_vwo_model'
require_relative '../../utils/uuid_util'
require_relative '../../services/settings_service'

class ContextModel
  attr_accessor :id, :user_agent, :ip_address, :custom_variables, :variation_targeting_variables, :post_segmentation_variables, :platform_variables, :vwo, :session_id, :uuid, :bucketing_seed

  def initialize(id = nil, user_agent = nil, ip_address = nil, custom_variables = {}, variation_targeting_variables = {}, post_segmentation_variables = {}, platform_variables = {}, vwo = nil, session_id = nil, uuid = nil, bucketing_seed = nil)
    @id = id
    @user_agent = user_agent
    @ip_address = ip_address
    @custom_variables = custom_variables || {}
    @variation_targeting_variables = variation_targeting_variables || {}
    @post_segmentation_variables = post_segmentation_variables || {}
    @platform_variables = platform_variables || {}
    @vwo = vwo
    @session_id = session_id
    @uuid = uuid
    @bucketing_seed = bucketing_seed
  end

  # Creates a model instance from a hash (dictionary)
  def model_from_dictionary(context)
    if context.key?(:customVariables) && !context[:customVariables].is_a?(Hash)
      raise TypeError, 'Invalid context, customVariables should be a hash'
    end

    if context.key?(:userAgent) && !context[:userAgent].is_a?(String)
      raise TypeError, 'Invalid context, userAgent should be a string'
    end

    if context.key?(:ipAddress) && !context[:ipAddress].is_a?(String)
      raise TypeError, 'Invalid context, ipAddress should be a string'
    end

    @id = context[:id]
    @user_agent = context[:userAgent]
    @ip_address = context[:ipAddress]
    @custom_variables = context[:customVariables] if context.key?(:customVariables)
    @variation_targeting_variables = context[:variationTargetingVariables] if context.key?(:variationTargetingVariables)
    @post_segmentation_variables = context[:postSegmentationVariables] if context.key?(:postSegmentationVariables)
    @platform_variables = context[:platformVariables] if context.key?(:platformVariables)
    @vwo = ContextVWOModel.new.model_from_dictionary(context[:_vwo]) if context.key?(:_vwo)
    @bucketing_seed = context[:bucketingSeed].to_s if context.key?(:bucketingSeed)

    # check if sessionId is present in context and should be non null and non empty
    if context.key?(:sessionId) && !context[:sessionId].nil? && !context[:sessionId].to_s.empty?
      @session_id = context[:sessionId].to_i
    else
      @session_id = Time.now.to_i
    end

    # check if uuid is present in context and should be non null and non empty string
    if context.key?(:uuid) && context[:uuid].is_a?(String) && !context[:uuid].empty?
      @uuid = context[:uuid]
    else
      @uuid = UUIDUtil.get_uuid(id.to_s, SettingsService.instance.account_id.to_s)
    end

    self
  end

  def get_id
    @id
  end

  def set_id(id)
    @id = id
  end

  def get_user_agent
    @user_agent
  end

  def set_user_agent(user_agent)
    @user_agent = user_agent
  end

  def get_ip_address
    @ip_address
  end

  def set_ip_address(ip_address)
    @ip_address = ip_address
  end

  def get_custom_variables
    @custom_variables
  end

  def set_custom_variables(custom_variables)
    @custom_variables = custom_variables
  end

  def get_variation_targeting_variables
    @variation_targeting_variables
  end

  def set_variation_targeting_variables(variation_targeting_variables)
    @variation_targeting_variables = variation_targeting_variables
  end

  def get_post_segmentation_variables
    @post_segmentation_variables
  end

  def set_post_segmentation_variables(post_segmentation_variables)
    @post_segmentation_variables = post_segmentation_variables
  end

  def get_platform_variables
    @platform_variables
  end

  def set_platform_variables(platform_variables)
    @platform_variables = platform_variables
  end

  def get_vwo
    @vwo
  end

  def set_vwo(vwo)
    @vwo = vwo
  end

  def get_session_id
    @session_id
  end

  def set_session_id(session_id)
    @session_id = session_id
  end

  def get_uuid
    @uuid
  end

  def set_uuid(uuid)
    @uuid = uuid
  end

  def get_bucketing_seed
    @bucketing_seed
  end

  def set_bucketing_seed(bucketing_seed)
    @bucketing_seed = bucketing_seed
  end
end
