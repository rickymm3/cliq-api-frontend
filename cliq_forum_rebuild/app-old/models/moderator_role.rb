# frozen_string_literal: true

class ModeratorRole < ApplicationRecord
  belongs_to :cliq
  belongs_to :user

  validates :started_at, presence: true
  validates :status, presence: true

  enum status: { active: "active", ended: "ended" }

  scope :active, -> { where(status: "active").where(ended_at: nil) }
  scope :recent, -> { order(started_at: :desc) }

  def conclude!(ended_at: Time.current)
    update!(status: "ended", ended_at: ended_at)
  end
end
