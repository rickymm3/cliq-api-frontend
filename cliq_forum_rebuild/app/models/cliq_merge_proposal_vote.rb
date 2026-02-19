class CliqMergeProposalVote < ApplicationRecord
  belongs_to :user
  belongs_to :cliq_merge_proposal

  validates :user_id, uniqueness: { scope: :cliq_merge_proposal_id }
  validates :value, inclusion: { in: [true, false] }

  after_save :update_proposal_counts
  after_destroy :update_proposal_counts

  private

  def update_proposal_counts
    cliq_merge_proposal.update_vote_counts
  end
end
