# frozen_string_literal: true

module Moderation
  module SlaCalculator
    module_function

    def next_expiry_for(cliq)
      hours = Moderation.config.sla_hours_for(cliq.rank_name)
      Time.current + hours.hours
    end
  end
end

