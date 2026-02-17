class Cliq < ApplicationRecord
  extend FriendlyId
  friendly_id :slug_candidates, use: :slugged

  MAX_CHILD_CLIQS = 7
  MAX_TREE_LEVELS = 7 # total levels counting root as level 1

  validates :name, presence: true, uniqueness: { scope: :parent_cliq_id, message: "must be unique under the same parent" }
  validate :parent_child_limit

  has_many :posts
  belongs_to :parent_cliq, class_name: 'Cliq', foreign_key: 'parent_cliq_id', optional: true
  has_many :child_cliqs, class_name: 'Cliq', foreign_key: :parent_cliq_id

  has_many :subscriptions, dependent: :destroy
  has_many :subscribers, through: :subscriptions, source: :user

  has_many :candidate_supports, dependent: :destroy
  has_many :moderator_roles, dependent: :destroy
  has_many :reports, dependent: :destroy
  has_many :moderation_delegations, dependent: :destroy

  enum rank: { unranked: 0, bronze: 1, silver: 2, gold: 3 }, _prefix: true

  alias_attribute :parent, :parent_cliq
  accepts_nested_attributes_for :posts


  def slug_candidates
    [
      [:parent_cliq_id, :name]
    ]
  end

  scope :ordered, -> { order(id: :desc) }
  scope :root, -> { where(parent_cliq_id: nil) }
  scope :main_categories, -> { where.not(parent_cliq_id: nil).where('parent_cliq_id IS NOT NULL') }

  # -------- Hierarchy helpers --------

  # IDs of all descendants (children, grandchildren, ...)
  def descendant_ids
    ids = []
    stack = child_cliqs.to_a
    until stack.empty?
      c = stack.pop
      ids << c.id
      stack.concat(c.child_cliqs)
    end
    ids
  end

  # Self + all descendants
  def self_and_descendant_ids
    [id] + descendant_ids
  end

  def self.search(query)
    where("name ILIKE ?", "%#{query}%") # Use ILIKE for case-insensitive matching
  end

  def should_generate_new_friendly_id?
    name_changed? || parent_cliq_id_changed?
  end

  def ancestors
    nodes = []
    current = self
    while current.parent_cliq
      current = current.parent_cliq
      break if current.name == "Cliq" # stop at umbrella/root
      nodes << current
    end
    nodes.reverse
  end

  # subscriptions
  def root_or_self
    ancestors.any? ? ancestors.first : self
  end

  def depth_from_root
    ancestors.length
  end

  def level_from_root
    depth_from_root + 1
  end

  def can_add_child?
    child_cliqs.count < MAX_CHILD_CLIQS && level_from_root < MAX_TREE_LEVELS
  end

  def rank_name
    rank&.to_s || "unranked"
  end

  def seats_for_rank
    Moderation.config.seats_for(rank_name)
  end

  def support_capacity_per_user
    Moderation.config.support_capacity_for(rank_name)
  end

  def sla_hours
    Moderation.config.sla_hours_for(rank_name)
  end

  def pending_reports
    reports.where(state: :pending)
  end

  def active_moderators
    moderator_roles.where(status: "active")
                   .where(ended_at: nil)
                   .order(started_at: :asc)
  end

  private

  def parent_child_limit
    return unless parent_cliq.present?

    existing_children = self.class.where(parent_cliq_id: parent_cliq_id).where.not(id: id).count
    if existing_children >= MAX_CHILD_CLIQS
      errors.add(:base, "This cliq already has the maximum number of child cliqs (#{MAX_CHILD_CLIQS}).")
    end

    if parent_cliq.level_from_root >= MAX_TREE_LEVELS
      errors.add(:base, "This cliq is already at the deepest level allowed.")
    end
  end
end
