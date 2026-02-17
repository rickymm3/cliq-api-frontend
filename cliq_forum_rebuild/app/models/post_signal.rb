class PostSignal < ApplicationRecord
  belongs_to :user
  belongs_to :post
  
  validates :user_id, uniqueness: { scope: :post_id, message: "has already signaled this post" }
  
  # Scope for active signals not older than 24 hours
  scope :active, -> { where('created_at > ?', 24.hours.ago) }
end
