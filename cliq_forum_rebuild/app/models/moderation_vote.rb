class ModerationVote < ApplicationRecord
  belongs_to :user
  belongs_to :post

  validates :user_id, uniqueness: { scope: :post_id }
  
  enum :vote_type, { keep: 0, delete: 1 }
end
