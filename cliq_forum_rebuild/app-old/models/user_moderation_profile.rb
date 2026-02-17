# frozen_string_literal: true

class UserModerationProfile < ApplicationRecord
  belongs_to :user

  validates :snapshot_at, presence: true

  scope :established, -> { where(established: true) }
end

