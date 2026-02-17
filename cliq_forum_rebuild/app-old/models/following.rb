# app/models/following.rb
class Following < ApplicationRecord
  # follower: the user who is following
  # followed: the user being followed
  belongs_to :follower, class_name: "User"
  belongs_to :followed, class_name: "User"

  # Ensure a user cannot follow the same person twice
  validates :follower_id, uniqueness: { scope: :followed_id }
end
