# frozen_string_literal: true

module Cliqs
  class RankSyncJob < ApplicationJob
    queue_as :default

    def perform
      Cliq.find_each do |cliq|
        Moderation::RankCalculator.new(cliq).call
      end
    end
  end
end

