class ModeratorSubscription < ApplicationRecord
  belongs_to :user
  belongs_to :cliq

  validates :user_id, uniqueness: { scope: :cliq_id }
end
