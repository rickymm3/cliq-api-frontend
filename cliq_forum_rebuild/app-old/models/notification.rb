# app/models/notification.rb
class Notification < ApplicationRecord
  belongs_to :user        # recipient
  belongs_to :actor, class_name: "User"
  belongs_to :notifiable, polymorphic: true

  scope :unread, -> { where(read_at: nil) }
end
