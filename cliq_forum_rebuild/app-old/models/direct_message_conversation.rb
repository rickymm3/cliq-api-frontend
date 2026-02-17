class DirectMessageConversation < ApplicationRecord
  belongs_to :user_a, class_name: "User"
  belongs_to :user_b, class_name: "User"

  has_many :messages,
           -> { order(created_at: :asc).includes(:sender, :recipient) },
           class_name: "DirectMessage",
           foreign_key: :conversation_id,
           dependent: :destroy,
           inverse_of: :conversation

  before_validation :normalize_participants

  validate :participants_are_unique
  validates :user_a, presence: true
  validates :user_b, presence: true

  scope :for_user, ->(user) { where("user_a_id = :id OR user_b_id = :id", id: user.id) }
  scope :ordered_by_recent_activity, -> { order(updated_at: :desc) }

  def self.between(user_one, user_two)
    ids = [user_one, user_two].map { |u| u.is_a?(User) ? u.id : u }.sort
    find_by(user_a_id: ids.first, user_b_id: ids.last)
  end

  def self.find_or_create_between!(user_one, user_two)
    ids = [user_one, user_two].map { |u| u.is_a?(User) ? u.id : u }.sort
    conversation = find_by(user_a_id: ids.first, user_b_id: ids.last)
    return conversation if conversation

    create!(user_a_id: ids.first, user_b_id: ids.last)
  end

  def includes?(user)
    user_a_id == user.id || user_b_id == user.id
  end

  def other_participant(user)
    return user_b if user_a_id == user.id
    return user_a if user_b_id == user.id

    nil
  end

  def unread_count_for(user)
    messages.for_recipient(user).unread.count
  end

  def last_message
    messages.last
  end

  private

  def normalize_participants
    return if user_a_id.blank? || user_b_id.blank?
    sorted_ids = [user_a_id, user_b_id].sort
    self.user_a_id, self.user_b_id = sorted_ids
  end

  def participants_are_unique
    return unless user_a_id.present? && user_b_id.present?
    errors.add(:base, "Participants must be different users") if user_a_id == user_b_id
  end
end
