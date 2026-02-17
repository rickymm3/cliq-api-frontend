# frozen_string_literal: true

module Moderation
  class RankCalculator
    attr_reader :cliq, :config

    def initialize(cliq, config: Moderation.config)
      @cliq = cliq
      @config = config
    end

    def call
      new_rank = determine_rank
      return if new_rank == cliq.rank

      cliq.update!(
        rank: new_rank,
        ranked_at: Time.current,
        rank_metadata: {
          points: rank_points,
          subscribers: subscriber_count,
          recent_posts: recent_post_count
        }
      )
    end

    private

    def determine_rank
      thresholds = config.ranks.transform_values { |settings| settings["min_rank_points"] || 0 }
      sorted = thresholds.sort_by { |_rank, points| points }
      chosen = sorted.select { |_rank, min_points| rank_points >= min_points }.last
      (chosen || ["unranked"]).first
    end

    def rank_points
      subscriber_count + (recent_post_count * 5)
    end

    def subscriber_count
      @subscriber_count ||= Subscription.where(cliq: cliq, enabled: true).count
    end

    def recent_post_count
      @recent_post_count ||= cliq.posts.where("created_at >= ?", 30.days.ago).count
    end
  end
end

