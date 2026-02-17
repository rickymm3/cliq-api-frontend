# frozen_string_literal: true

module Moderation
  module_function

  def config
    @config ||= Config.new(Rails.configuration.x.cliq.fetch(:moderation, {}))
  end

  def reset_config_cache!
    @config = nil
  end
end

