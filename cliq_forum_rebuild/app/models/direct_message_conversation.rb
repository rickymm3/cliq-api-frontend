class DirectMessageConversation < ApplicationRecord
	belongs_to :user_a, class_name: "User"
	belongs_to :user_b, class_name: "User"
	has_many :messages, -> { order(created_at: :asc).includes(:sender, :recipient) }, class_name: "DirectMessage", foreign_key: :conversation_id, dependent: :destroy, inverse_of: :conversation
end
