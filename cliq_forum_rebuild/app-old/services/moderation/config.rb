# frozen_string_literal: true

module Moderation
  class Config
    attr_reader :raw

    def initialize(raw)
      @raw = (raw || {}).with_indifferent_access
    end

    def eligibility
      raw.fetch(:eligibility, {})
    end

    def rate_limits
      raw.fetch(:rate_limits, {})
    end

    def ranks
      raw.fetch(:ranks, {})
    end

    def rank_keys
      ranks.keys.map(&:to_s)
    end

    def rank_settings(rank)
      ranks.fetch(rank.to_s) { ranks.fetch("unranked", {}) }
    end

    def seats_for(rank)
      rank_settings(rank).fetch("seats", 0)
    end

    def support_capacity_for(rank)
      rank_settings(rank).fetch("support_capacity", 0)
    end

    def sla_hours_for(rank)
      rank_settings(rank).fetch("sla_hours", 24)
    end

    def liquid_democracy_enabled?
      raw.dig(:liquid_democracy, :enabled) == true
    end

    def max_delegate_depth
      raw.dig(:liquid_democracy, :delegate_max_depth) || 1
    end

    def transparency_window_days
      raw.dig(:transparency, :actions_window_days) || 30
    end

    def include_transparency_counts?
      raw.dig(:transparency, :include_counts) != false
    end
  end
end

