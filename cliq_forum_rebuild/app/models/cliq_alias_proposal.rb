class CliqAliasProposal < ApplicationRecord
  belongs_to :cliq
  belongs_to :parent_cliq, class_name: 'Cliq', foreign_key: 'parent_cliq_id'
  belongs_to :proposer, class_name: 'User', foreign_key: 'proposer_id'

  validates :alias_name, presence: true
  
  # Ensure unique proposal for same cliq in same parent
  validates :cliq_id, uniqueness: { scope: :parent_cliq_id, message: "already has a proposal for this parent category" }

  enum :status, { pending: 0, approved: 1, rejected: 2 }

  # Constants
  APPROVAL_THRESHOLD = 5

  def upvote!
    increment!(:votes_count)
    check_approval_status
  end

  private

  def check_approval_status
    if votes_count >= APPROVAL_THRESHOLD
      approve!
    end
  end

  def approve!
    return unless pending?

    transaction do
      update!(status: :approved)
      create_alias_cliq
    end
  end

  def create_alias_cliq
    Cliq.create!(
      name: alias_name,
      description: "Alias for #{cliq.name}",
      parent_cliq_id: parent_cliq_id,
      canonical_id: cliq.id,
      lens: lens,
      rank: 0 # Default rank
    )
  end
end
