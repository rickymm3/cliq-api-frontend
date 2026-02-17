class PostInteraction < ApplicationRecord
  belongs_to :user
  belongs_to :post
  
  enum :preference, { neutral: 0, like: 1, dislike: 2 }
  
  validates :user_id, uniqueness: { scope: :post_id }
end
