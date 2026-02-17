# frozen_string_literal: true

class CandidateSupport < ApplicationRecord
  belongs_to :user
  belongs_to :candidate_user, class_name: "User"
  belongs_to :cliq
  belongs_to :post, counter_cache: :moderation_supports_count

  validates :user_id, uniqueness: { scope: [:cliq_id, :candidate_user_id], message: "already supported this candidate in the cliq" }
  validates :weight, numericality: { greater_than: 0 }
  validate :supporter_is_established
  validate :support_limits_not_exceeded
  validate :respect_support_rate_limit, on: :create
  validate :post_matches_candidate
  validate :prevent_self_support

  scope :for_cliq, ->(cliq) { where(cliq: cliq) }

  after_commit :broadcast_support_change, on: [:create, :destroy]

  private

  def supporter_is_established
    return if Moderation::Eligibility.established?(user)
    errors.add(:base, "You must be an established member to support candidates.")
  end

  def support_limits_not_exceeded
    return unless errors.empty?

    capacity = Moderation::SupportCapacity.new(cliq, user)
    return if capacity.can_support?(candidate_user_id)

    errors.add(:base, "You reached the support limit for this cliq.")
  end

  def respect_support_rate_limit
    limiter = Moderation::RateLimiter.new(user)
    return if limiter.support_actions_within_limit?(cliq)

    errors.add(:base, "You've reached the support rate limit for this cliq. Try again later.")
  end

  def post_matches_candidate
    return if post.cliq_id == cliq_id && post.user_id == candidate_user_id && post.visibility_moderation?
    errors.add(:post_id, "must point to the candidate's moderation post within the cliq.")
  end

  def prevent_self_support
    return unless user_id == candidate_user_id
    errors.add(:base, "You cannot support yourself.")
  end

  def broadcast_support_change
    Moderation::Broadcaster.support_updated!(post)
  rescue StandardError => e
    Rails.logger.error("Failed to broadcast support change for post #{post_id}: #{e.message}")
  end
end
