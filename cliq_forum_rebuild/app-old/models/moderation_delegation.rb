# frozen_string_literal: true

class ModerationDelegation < ApplicationRecord
  belongs_to :delegator, class_name: "User"
  belongs_to :delegatee, class_name: "User"
  belongs_to :cliq

  validates :granted_at, presence: true
  validate :prevent_self_delegation

  scope :active, -> { where(active: true, revoked_at: nil) }

  def revoke!(at: Time.current)
    update!(active: false, revoked_at: at)
  end

  private

  def prevent_self_delegation
    return unless delegator_id == delegatee_id
    errors.add(:delegatee_id, "cannot be the same as delegator")
  end
end

