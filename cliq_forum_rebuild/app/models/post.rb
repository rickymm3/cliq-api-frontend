class Post < ApplicationRecord
	extend FriendlyId
	friendly_id :title, use: :slugged

	belongs_to :cliq
	belongs_to :user
	has_many :replies, dependent: :destroy
	has_many :post_interactions, dependent: :destroy
  has_many :post_signals, dependent: :destroy
  has_many :moderation_votes, dependent: :destroy
  has_many :post_links, dependent: :destroy
  has_many :reports, as: :reportable, dependent: :destroy
  has_many :post_visits, dependent: :destroy
  has_many :post_daily_stats, dependent: :destroy

  belongs_to :cliq_merge_proposal, optional: true # Only for merge proposals
  belongs_to :cliq_alliance_proposal, optional: true # Only for alliance proposals

  # Kind logic
  enum :kind, { default_post: 0, merge_proposal: 1, alliance_proposal: 2 }

	has_rich_text :content

  # Helper to check if post is linked to a lens
  def linked_to?(lens_id)
    post_links.exists?(lens_id: lens_id)
  end

  enum :visibility, { visible: 0, hidden_old: 1, removed: 2 } # Renaming to avoid conflict if needed, or keeping for legacy
  enum :status, { active: 0, contentious: 1, hidden: 2, deleted: 3 }, prefix: true

	scope :by_heat, -> { order(heat_score: :desc) }

	def calculate_heat
		HeatCalculator.calculate(self)
	end
end
