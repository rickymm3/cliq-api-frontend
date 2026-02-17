class Subscription < ApplicationRecord
  belongs_to :user
  belongs_to :cliq
  validates :user_id, uniqueness: { scope: :cliq_id }

  attribute :enabled, :boolean, default: true
end
