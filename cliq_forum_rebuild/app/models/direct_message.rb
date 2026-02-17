class DirectMessage < ApplicationRecord
	belongs_to :conversation, class_name: "DirectMessageConversation", inverse_of: :messages, touch: true
	belongs_to :sender, class_name: "User"
	belongs_to :recipient, class_name: "User"
end
