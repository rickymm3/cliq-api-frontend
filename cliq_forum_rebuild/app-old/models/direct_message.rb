class DirectMessage < ApplicationRecord
  belongs_to :conversation,
             class_name: "DirectMessageConversation",
             inverse_of: :messages,
             touch: true
  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"

  validates :body, presence: true
  validate :sender_participates_in_conversation
  validate :recipient_participates_in_conversation

  scope :unread, -> { where(read_at: nil) }
  scope :for_recipient, ->(user) { where(recipient_id: user.id) }

  def mark_as_read!
    return if read_at?
    update!(read_at: Time.current)
  end

  private

  def sender_participates_in_conversation
    return unless conversation && sender
    errors.add(:sender, "must be part of the conversation") unless conversation.includes?(sender)
  end

  def recipient_participates_in_conversation
    return unless conversation && recipient
    errors.add(:recipient, "must be part of the conversation") unless conversation.includes?(recipient)
  end
end
