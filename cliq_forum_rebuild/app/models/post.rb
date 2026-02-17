class Post < ApplicationRecord
	extend FriendlyId
	friendly_id :title, use: :slugged

	belongs_to :cliq
	belongs_to :user
	has_many :replies, dependent: :destroy
	has_many :post_interactions, dependent: :destroy
  has_many :post_signals, dependent: :destroy
  has_many :moderation_votes, dependent: :destroy
	has_rich_text :content

  enum :visibility, { visible: 0, hidden: 1, removed: 2 }

	scope :by_heat, -> { order(heat_score: :desc) }

	def calculate_heat
		HeatCalculator.calculate(self)
	end
end
