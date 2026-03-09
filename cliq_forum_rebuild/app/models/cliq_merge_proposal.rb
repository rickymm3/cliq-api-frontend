class CliqMergeProposal < ApplicationRecord
  belongs_to :source_cliq, class_name: 'Cliq'
  belongs_to :target_cliq, class_name: 'Cliq'
  belongs_to :proposer, class_name: 'User'
  has_many :votes, class_name: 'CliqMergeProposalVote', dependent: :destroy

  # A merge proposal is discussed via a Post. It belongs to a Post, or a Post belongs to it?
  # The migration added `cliq_merge_proposal_id` to `posts`.
  # This implies a Proposal can have multiple posts discussing it? Or just one main post?
  # Usually "Proposal Post" implies one main post.
  has_one :post, dependent: :destroy
  
  enum :status, { 
    proposal_phase: 0, 
    verification_phase: 1, 
    approved: 2, 
    rejected: 3, 
    expired: 4 
  }, default: :proposal_phase

  validates :source_cliq, presence: true
  validates :target_cliq, presence: true
  validates :source_cliq_id, uniqueness: { scope: [:target_cliq_id, :status], message: "already has an active merge proposal with this target", conditions: -> { where.not(status: [:approved, :rejected, :expired]) } }

  # Updates the cached vote counts and checks if the proposal should advance
  def update_vote_counts
    self.yes_votes = votes.where(value: true).count
    self.no_votes = votes.where(value: false).count
    
    # Save without validation to avoid loop if validates calls something that triggers this
    save(validate: false)

    # Admin God Mode check
    admin_vote = votes.joins(:user).where(users: { admin: true }).last
    if admin_vote
      process_admin_vote(admin_vote.value)
    else
      check_threshold
    end
  end

  def vote!(user, value)
    transaction do
      vote = votes.find_or_initialize_by(user: user)
      vote.value = value
      vote.save!
    end
  end

  private

  def process_admin_vote(value)
    if value
      # God Mode: Admin approval bypasses all phases immediately
      approve!
    else
      reject!
    end
  end

  def check_threshold
    return unless proposal_phase?

    if yes_votes >= threshold
      # Move to next phase
      # Logic: Lock post, create new post in target, etc.
      # For now, just change status.
      update!(status: :verification_phase)
    elsif no_votes >= threshold
      update!(status: :rejected)
    end
  end

  def approve!
    return if approved?
    transaction do
      update!(status: :approved)
    end
  end

  def reject!
    update!(status: :rejected)
  end

  def threshold
    # Placeholder for dynamic threshold logic. 
    # Could be based on source_cliq.subscribers.count * 0.1
    5 
  end
end
