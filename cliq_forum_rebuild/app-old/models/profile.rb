# app/models/profile.rb
class Profile < ApplicationRecord
  belongs_to :user
  validates :username, presence: true, uniqueness: { case_sensitive: false }, length: { minimum: 3, maximum: 12 }

  # Override to_param so that URL helpers use the username as the identifier.
  def to_param
    username
  end
end
