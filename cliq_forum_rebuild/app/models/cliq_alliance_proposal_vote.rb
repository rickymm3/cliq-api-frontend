class CliqAllianceProposalVote < ApplicationRecord
  belongs_to :user
  belongs_to :cliq_alliance_proposal
  
  validates :user_id, uniqueness: { scope: :cliq_alliance_proposal_id, message: "has already voted on this proposal" }
end
