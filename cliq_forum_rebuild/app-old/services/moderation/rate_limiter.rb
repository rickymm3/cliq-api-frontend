# frozen_string_literal: true

module Moderation
  class RateLimiter
    attr_reader :user, :config

    def initialize(user, config: Moderation.config)
      @user = user
      @config = config
    end

    def can_create_moderation_post?(cliq)
      limit = config.rate_limits.fetch("moderation_post_limit", 1)
      return true if limit.zero?

      window_days = config.rate_limits.fetch("moderation_post_window_days", 30)
      window_start = window_days.days.ago
      recent_posts = user.posts.where(visibility: Post.visibilities[:moderation], cliq: cliq)
                               .where("created_at >= ?", window_start)
                               .count
      recent_posts < limit
    end

    def support_actions_within_limit?(cliq)
      limit = config.rate_limits.fetch("support_action_limit", 25)
      return true if limit.zero?

      window_hours = config.rate_limits.fetch("support_action_window_hours", 24)
      window_start = window_hours.hours.ago
      recent_supports = user.candidate_supports.where(cliq: cliq)
                                               .where("created_at >= ?", window_start)
                                               .count
      recent_supports < limit
    end

    def report_within_limit?
      limit = config.rate_limits.fetch("report_limit", 10)
      return true if limit.zero?

      window_hours = config.rate_limits.fetch("report_window_hours", 12)
      window_start = window_hours.hours.ago
      user.reports.where("created_at >= ?", window_start).count < limit
    end
  end
end

