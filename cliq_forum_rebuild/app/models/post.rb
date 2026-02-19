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
  belongs_to :cliq_merge_proposal, optional: true # Only for merge proposals

  # Kind logic
  enum :kind, { default_post: 0, merge_proposal: 1 }

	has_rich_text :content

  # Helper to check if post is linked to a lens
  def linked_to?(lens_id)
    post_links.exists?(lens_id: lens_id)
  end

  enum :visibility, { visible: 0, hidden: 1, removed: 2 }

	scope :by_heat, -> { order(heat_score: :desc) }

	def calculate_heat
		HeatCalculator.calculate(self)
	end
end
