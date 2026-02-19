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
  
  # Analytics
  has_many :cliq_visits, dependent: :delete_all
  has_many :cliq_daily_stats, dependent: :destroy
  
  # Merge Proposals
  has_many :source_merge_proposals, class_name: 'CliqMergeProposal', foreign_key: 'source_cliq_id', dependent: :destroy
  has_many :target_merge_proposals, class_name: 'CliqMergeProposal', foreign_key: 'target_cliq_id', dependent: :destroy

  # Returns the unique visitor count for the last 7 days (rolling)
  def weekly_unique_visitors
    # Calculate directly from raw visits if available (most accurate for recent window)
    cliq_visits.where(visited_on: 6.days.ago..Date.today).count
  end

  # Returns total historical unique visitors
  def total_unique_visitors
    aggregated = cliq_daily_stats.sum(:unique_visits_count)
    today = cliq_visits.where(visited_on: Date.today).count
    aggregated + today
  end

  # Canonical & Alias Logic
  belongs_to :canonical, class_name: 'Cliq', foreign_key: 'canonical_id', optional: true
  has_many :aliases, class_name: 'Cliq', foreign_key: 'canonical_id', dependent: :nullify

  # Helper to determine if this cliq is an alias
  def alias?
    canonical_id.present?
  end

  # Helper to get the effective cliq (self if canonical, or the target canonical)
  def effective_cliq
    alias? ? canonical : self
  end
  
  # Helper to get the lens this cliq filters by (if it is an alias)
  def effective_lens
    lens
  end

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

	# Hierarchy Helper
	def hierarchy_string
		names = [name]
		current = parent_cliq
		safety_counter = 0
		while current && safety_counter < 15 # Prevent infinite loops
			names.unshift(current.name)
			current = current.parent_cliq
			safety_counter += 1
		end
		
		# User requested to remove the root 'Cliq' label from the hierarchy
		names.shift if names.size > 1 && names.first.downcase == 'cliq'
		
		names.join(" > ")
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
