class Reply < ApplicationRecord
  belongs_to :post, counter_cache: true
  belongs_to :user

  belongs_to :parent_reply, class_name: "Reply", optional: true
  has_many   :child_replies, class_name: "Reply", foreign_key: :parent_reply_id, dependent: :nullify

  has_rich_text :content

  validates :content, presence: true
  # NOTE: no uniqueness validation on :parent_reply_id

  validate :parent_must_be_top_level

  scope :top_level, -> { where(parent_reply_id: nil) }

  after_create :bump_post_heat

  def can_accept_child_reply?
    parent_reply_id.nil?
  end

  private

  def parent_must_be_top_level
    return unless parent_reply_id.present?
    if parent_reply&.parent_reply_id.present?
      errors.add(:parent_reply_id, "can only reply to a top-level reply")
    end
  end

  def bump_post_heat
    post&.bump_heat!(:reply)
  end
end
