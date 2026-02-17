class Cliq < ApplicationRecord
	has_many :posts, counter_cache: :posts_count
	belongs_to :parent_cliq, class_name: 'Cliq', foreign_key: 'parent_cliq_id', optional: true
	has_many :child_cliqs, class_name: 'Cliq', foreign_key: :parent_cliq_id
	has_many :subscriptions, dependent: :destroy
	has_many :subscribers, through: :subscriptions, source: :user
	has_many :moderator_roles, dependent: :destroy
  has_many :moderator_subscriptions, dependent: :destroy
  has_many :moderators, through: :moderator_subscriptions, source: :user
	has_many :reports, dependent: :destroy

	# Validations
	validates :name, presence: true
	validates :name, uniqueness: { scope: :parent_cliq_id, message: "already exists in this cliq" }
	validate :validate_hierarchy_depth, on: :create

	def validate_hierarchy_depth
		return unless parent_cliq

		# Count ancestors to determine depth
		# Root is depth 0. Main categories are depth 1.
		# User allows 8 levels deep from main categories (Depth 1 + 8 = Depth 9).
		# We prevent creating nodes at Depth 10.
		# If parent is at Depth 9, its ancestor chain (including itself) has 10 nodes (L9..L0).
		
		depth_count = 0
		current = parent_cliq
		while current
			depth_count += 1
			current = current.parent_cliq
			
			if depth_count >= 10
				errors.add(:base, "Maximum sub-cliq depth reached (8 levels from main category)")
				break
			end
		end
	end

	# Get all descendant cliqs (children, grandchildren, etc.)
	def descendants
		child_cliqs.includes(:child_cliqs).flat_map { |child| [child] + child.descendants }
	end

	# Get top child cliqs ranked by popularity and manual rank
	# Scoring: (posts_count × 0.4) + (rank × 10)
	scope :top_children, ->(limit = 10) {
		order(Arel.sql("COALESCE(cliqs.posts_count, 0) * 0.4 + COALESCE(cliqs.rank, 0) * 10 DESC"))
			.limit(limit)
	}
end
