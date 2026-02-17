# app/models/post.rb
class Post < ApplicationRecord
  extend FriendlyId
  friendly_id :title_truncated, use: :slugged

  HEAT_WEIGHTS = {
    view: 1.0,
    click: 2.0,
    reply: 15.0,
    edit: 5.0,
    create: 10.0
  }.freeze

  HEAT_THRESHOLD = 100.0
  HOT_DURATION = 24.hours
  HEAT_DECAY_HALF_LIFE = 12.hours
  HEAT_DECAY_RATE = Math.log(2) / HEAT_DECAY_HALF_LIFE.to_f

  belongs_to :cliq
  belongs_to :user
  has_many :replies, dependent: :destroy
  has_rich_text :content

  has_one_attached :lead_image
  has_one_attached :article_header_image
  has_one_attached :article_inline_image_one
  has_one_attached :article_inline_image_two

  # 👇 Make the type explicit so enum never complains
  attribute :post_type, :integer, default: 0

  # Backed by posts.post_type (integer)
  enum post_type: { discussion: 0, article: 1, question: 2 }
  enum visibility: { public: 0, moderation: 1 }, _prefix: true

  scope :visible_in_feeds, -> { where.not(visibility: visibilities[:moderation]) }
  scope :moderation_posts, -> { where(visibility: visibilities[:moderation]) }

  scope :ordered, -> { order(updated_at: :desc) }
  scope :articles, -> { where(post_type: :article) }  # ← convenience
  scope :hot, -> { where("hot_until IS NOT NULL AND hot_until >= ?", Time.current) }
  scope :for_cliq, ->(cliq_id) { where(cliq_id: cliq_id) }

  after_commit :register_creation!, on: :create
  after_create :notify_followers
  after_commit :notify_followers_of_article, on: :create
  validate :validate_image_configuration
  before_save :set_moderation_tagged_at

  has_many :candidate_supports, dependent: :destroy

  def moderation_candidate?
    visibility_moderation?
  end

  def moderation_supports_count!
    candidate_supports.count
  end

  def supports_remaining_for(user)
    return 0 unless user
    Moderation::SupportCapacity.new(cliq, user).remaining_for_candidate(self)
  end

  def toggle_moderation_visibility!
    visibility_public? ? visibility_moderation! : visibility_public!
  end

  def seat_support_snapshot
    {
      cliq_id: cliq_id,
      candidate_user_id: user_id,
      support_count: moderation_supports_count
    }
  end

  def title_truncated
    title.to_s.truncate(20, omission: '')
  end

  def should_generate_new_friendly_id?
    title_changed? || super
  end

  def hot?
    hot_until.present? && hot_until >= Time.current
  end

  private

  def bump_heat!(event)
    amount = HEAT_WEIGHTS[event.to_sym]
    return unless amount

    now = Time.current
    decayed_score = apply_heat_decay(now)
    new_score = decayed_score + amount

    attributes = {
      heat_score: new_score,
      heat_score_updated_at: now
    }

    if new_score >= HEAT_THRESHOLD
      attributes[:hot_until] = [now + HOT_DURATION, hot_until || now].max
    elsif hot_until.present? && hot_until < now
      attributes[:hot_until] = nil
    end

    update_columns(attributes)
  end

  def apply_heat_decay(current_time)
    baseline_time = heat_score_updated_at || created_at || updated_at || current_time
    elapsed = current_time - baseline_time
    return heat_score.to_f if elapsed <= 0

    (heat_score.to_f * Math.exp(-elapsed * HEAT_DECAY_RATE)).clamp(0.0, Float::INFINITY)
  end

  def register_view!
    bump_heat!(:view)
  end

  def register_click!
    bump_heat!(:click)
  end

  def register_edit!
    bump_heat!(:edit)
  end

  def register_creation!
    bump_heat!(:create)
  end

  public :register_view!, :register_click!, :register_edit!, :register_creation!, :bump_heat!

  def notify_followers
    return unless cliq && user_id.present?

    cliq_ids = [cliq.id]
    cliq_ids.concat(cliq.ancestors.map(&:id)) if cliq.respond_to?(:ancestors)
    cliq_ids.compact!

    subscriber_ids = Subscription.where(cliq_id: cliq_ids, enabled: true)
                                  .where.not(user_id: user_id)
                                  .distinct
                                  .pluck(:user_id)
    return if subscriber_ids.empty?

    actor_name = user.profile&.username || user.email || "Someone"
    message = "#{actor_name} posted in #{cliq.name}: #{title}"
    timestamp = Time.current

    Notification.insert_all(
      subscriber_ids.map do |recipient_id|
        {
          user_id:         recipient_id,
          actor_id:        user_id,
          notifiable_type: "Post",
          notifiable_id:   id,
          message:         message,
          created_at:      timestamp,
          updated_at:      timestamp
        }
      end
    )
  end

  def notify_followers_of_article
    return unless article? && user_id.present?

    follower_ids = FollowedUser.where(followed_id: user_id).pluck(:follower_id)
    return if follower_ids.empty?

    Notification.insert_all(
      follower_ids.map do |recipient_id|
        {
          user_id:         recipient_id,
          actor_id:        user_id,
          notifiable_type: "Post",
          notifiable_id:   id,
          message:         "New article by #{user.profile&.username || user.email || "a user"}: #{title}",
          created_at:      Time.current,
          updated_at:      Time.current
        }
      end
    )
  end

  def primary_display_image
    return article_header_image if article? && article_header_image.attached?
    lead_image if lead_image.attached?
  end

  def article_inline_image(position)
    case position
    when 1 then article_inline_image_one
    when 2 then article_inline_image_two
    end
  end

  def article_inline_images
    [article_inline_image_one, article_inline_image_two].select(&:attached?)
  end

  public :primary_display_image, :article_inline_image, :article_inline_images

  private

  ALLOWED_IMAGE_TYPES = %w[image/png image/jpeg image/jpg image/webp image/gif].freeze
  def validate_image_configuration
    validate_lead_image
    validate_article_images
  end

  def validate_lead_image
    return unless lead_image.attached?

    if article?
      errors.add(:lead_image, "is only used for regular posts") # encourage header usage for articles
    end

    validate_attachment_content_type(lead_image, :lead_image)
  end

  def validate_article_images
    unless article?
      errors.add(:article_header_image, "is only for articles") if article_header_image.attached?
      errors.add(:article_inline_image_one, "is only for articles") if article_inline_image_one.attached?
      errors.add(:article_inline_image_two, "is only for articles") if article_inline_image_two.attached?
      return
    end

    validate_attachment_content_type(article_header_image, :article_header_image) if article_header_image.attached?

    validate_attachment_content_type(article_inline_image_one, :article_inline_image_one) if article_inline_image_one.attached?
    validate_attachment_content_type(article_inline_image_two, :article_inline_image_two) if article_inline_image_two.attached?
  end

  def validate_attachment_content_type(attachment, attribute)
    return unless attachment&.blob

    unless ALLOWED_IMAGE_TYPES.include?(attachment.blob.content_type)
      errors.add(attribute, "must be an image (PNG, JPG, WEBP, or GIF)")
    end
  end

  def set_moderation_tagged_at
    return unless will_save_change_to_visibility? && visibility_moderation?
    self.moderation_tagged_at ||= Time.current
  end
end
