# frozen_string_literal: true

module Moderation
  class SupportCapacity
    attr_reader :cliq, :user, :config

    def initialize(cliq, user, config: Moderation.config)
      @cliq = cliq
      @user = user
      @config = config
    end

    def max_capacity
      return 0 unless cliq.present? && user.present?
      rank_setting = config.rank_settings(cliq.rank_name)
      rank_setting.fetch("support_capacity", 0)
    end

    def used_capacity
      @used_capacity ||= CandidateSupport.where(cliq: cliq, user: user).count
    end

    def remaining_capacity
      [max_capacity - used_capacity, 0].max
    end

    def can_support?(candidate_user_id)
      return false unless core_requirements_met?
      return true if already_supporting?(candidate_user_id)
      remaining_capacity.positive?
    end

    def remaining_for_candidate(post)
      return 0 unless post&.cliq == cliq
      return remaining_capacity if already_supporting?(post.user_id)
      remaining_capacity
    end

    private

    def core_requirements_met?
      cliq.present? && user.present? && Moderation::Eligibility.established?(user) && max_capacity.positive?
    end

    def already_supporting?(candidate_user_id)
      CandidateSupport.exists?(cliq: cliq, user: user, candidate_user_id: candidate_user_id)
    end
  end
end

