class CliqAllianceProposal < ApplicationRecord
  belongs_to :proposer, class_name: 'User'
  belongs_to :source_cliq, class_name: 'Cliq'
  belongs_to :target_cliq, class_name: 'Cliq'
  has_many :votes, class_name: 'CliqAllianceProposalVote', dependent: :destroy
  has_one :post, dependent: :destroy

  attribute :kind, :integer, default: 0
  enum :kind, { create_alliance: 0, disband_alliance: 1 }, default: :create_alliance
  enum :status, { 
    proposal_phase: 0, 
    approved: 1, 
    rejected: 2
  }, default: :proposal_phase

  validates :source_cliq, presence: true
  validates :target_cliq, presence: true
  
  # Prevent duplicate active proposals for the same pair
  validate :no_active_proposal_exists, on: :create, if: -> { source_cliq_id.present? && target_cliq_id.present? }

  def active?
    proposal_phase?
  end

  # Updates the cached vote counts and checks if the proposal should advance
  def update_vote_counts
    self.yes_votes = votes.where(value: true).count
    self.no_votes = votes.where(value: false).count
    
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
    update_vote_counts
  end

  private

  def process_admin_vote(value)
    if value
      approve!
    else
      reject!
    end
  end


  def no_active_proposal_exists
    if CliqAllianceProposal.where(source_cliq_id: source_cliq_id, target_cliq_id: target_cliq_id, status: :proposal_phase).exists?
      errors.add(:base, "An active alliance proposal already exists for this cliq pair.")
    end
  end

  def check_threshold
    return unless proposal_phase?

    if yes_votes >= threshold
      approve!
    elsif no_votes >= threshold
      reject!
    end
  end

  def approve!
    return if approved? # Guard against double approval
    
    transaction do
      update!(status: :approved)
      if disband_alliance?
        # Destroy alliance (check both directions)
        CliqAlliance.where(source_cliq: source_cliq, target_cliq: target_cliq).destroy_all
        CliqAlliance.where(source_cliq: target_cliq, target_cliq: source_cliq).destroy_all
      else
        CliqAlliance.find_or_create_by!(source_cliq: source_cliq, target_cliq: target_cliq)
      end
    end
  end
  
  def reject!
    update!(status: :rejected)
  end
end
