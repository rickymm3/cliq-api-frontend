# frozen_string_literal: true

module Cliqs
  class ModeratorElectionJob < ApplicationJob
    queue_as :default

    def perform
      Cliq.find_each do |cliq|
        Moderation::Election.new(cliq).call
      end
    end
  end
end

