# frozen_string_literal: true

module Reports
  class EscalationJob < ApplicationJob
    queue_as :default

    def perform
      Report.where(state: [Report::STATES[:pending], Report::STATES[:escalated]]).find_each do |report|
        next unless report.sla_expired?

        next_cliq = report.cliq.parent_cliq
        if next_cliq
          report.escalate!(next_cliq)
        else
          actor = system_actor
          report.resolve!(actor: actor, action: "auto_resolved") if actor
        end
      end
    end

    private

    def system_actor
      User.find_by(email: Rails.configuration.x.cliq.dig(:moderation, :system_actor_email)) || User.first
    end
  end
end
