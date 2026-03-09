class ModerationVote < ApplicationRecord
  belongs_to :user
  belongs_to :voteable, polymorphic: true

  enum :vote_type, { remove: 0, keep: 1 }

  validates :user_id, uniqueness: { scope: [:voteable_type, :voteable_id] }

  after_create_commit :check_consensus

  private

  def check_consensus
    # Admin Override
    admin_vote = ModerationVote.where(voteable: voteable).joins(:user).where(users: { admin: true }).last
    if admin_vote
      if admin_vote.keep?
        voteable.update(status: :active, hidden_at: nil)
      elsif admin_vote.remove?
        voteable.update(status: :deleted)
      end
      return
    end

    # Example Logic: 
    # If distinct users vote KEEP > threshold -> Restore
    # If distinct users vote REMOVE > threshold -> Delete
    # Threshold could be dynamic based on heat or static (e.g., 5 votes net)
    
    keep_votes = ModerationVote.where(voteable: voteable, vote_type: :keep).count
    remove_votes = ModerationVote.where(voteable: voteable, vote_type: :remove).count
    
    total_votes = keep_votes + remove_votes
    
    # Simple majority rule for now with minimum quorum of 3
    if total_votes >= 3
      if keep_votes > remove_votes
        voteable.update(status: :active, hidden_at: nil)
        # Ideally clean up reports here too
      elsif remove_votes > keep_votes
        voteable.update(status: :deleted)
      end
    end
  end
end
