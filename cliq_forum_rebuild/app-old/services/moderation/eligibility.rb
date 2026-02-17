# frozen_string_literal: true

module Moderation
  class Eligibility
    attr_reader :user, :snapshot, :config

    def self.established?(user)
      new(user).established?
    end

    def initialize(user, config: Moderation.config)
      @user = user
      @config = config
      @snapshot = user&.user_moderation_profile
    end

    def established?
      return false unless user.present?

      meets_account_age? && meets_activity_score? && within_strike_limits?
    end

    def meets_account_age?
      age_threshold = config.eligibility.fetch("minimum_account_age_days", 0)
      return true if age_threshold.zero?
      account_age_days >= age_threshold
    end

    def meets_activity_score?
      required_score = config.eligibility.fetch("minimum_activity_score", 0)
      return true if required_score.zero?
      activity_score >= required_score
    end

    def within_strike_limits?
      max_strikes = config.eligibility.fetch("maximum_active_strikes", 0)
      current_strikes <= max_strikes
    end

    def account_age_days
      if snapshot&.account_age_days.present?
        snapshot.account_age_days
      else
        ((Time.current - (user.created_at || Time.current)) / 1.day).floor
      end
    end

    def activity_score
      snapshot&.activity_score || compute_activity_score_from_history
    end

    def current_strikes
      snapshot&.strike_count || 0
    end

    private

    def compute_activity_score_from_history
      posts = user.posts.count
      replies = user.replies.count
      (posts * 10) + (replies * 5)
    end
  end
end

