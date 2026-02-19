module Api
  class CliqAliasProposalsController < BaseController
    before_action :authenticate_api_user!

    # GET /api/cliqs/:cliq_id/alias_proposals
    def index
      cliq = Cliq.find(params[:cliq_id])
      proposals = CliqAliasProposal.where(cliq: cliq, status: :pending)
                                   .includes(:parent_cliq, :proposer)
                                   .order(votes_count: :desc)
      
      render json: serialize_proposals(proposals)
    end

    # POST /api/cliqs/:cliq_id/alias_proposals
    def create
      cliq = Cliq.find(params[:cliq_id])
      
      # Basic authorization: User must have some reputation or account age
      # For now, we'll just check if they are logged in (handled by before_action)
      
      proposal = CliqAliasProposal.new(proposal_params)
      proposal.cliq = cliq
      proposal.proposer = current_user
      
      if proposal.save
        render json: serialize_proposal(proposal), status: :created
      else
        render json: { errors: proposal.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # POST /api/alias_proposals/:id/vote
    def vote
      proposal = CliqAliasProposal.find(params[:id])
      
      # TODO: Implement vote tracking to prevent duplicate votes per user per proposal.
      # For MVP, we just upvote.
      
      proposal.upvote!
      
      render json: { 
        status: "success", 
        data: serialize_proposal(proposal),
        message: proposal.approved? ? "Vote recorded. Proposal approved!" : "Vote recorded."
      }
    end

    private

    def proposal_params
      params.require(:proposal).permit(:parent_cliq_id, :alias_name, :lens)
    end

    def serialize_proposals(proposals)
      {
        data: proposals.map { |p| serialize_proposal(p) }
      }
    end

    def serialize_proposal(proposal)
      {
        id: proposal.id,
        alias_name: proposal.alias_name,
        lens: proposal.lens,
        parent_cliq_name: proposal.parent_cliq.name,
        votes_count: proposal.votes_count,
        threshold: CliqAliasProposal::APPROVAL_THRESHOLD,
        status: proposal.status,
        proposer: {
          id: proposal.proposer.id,
          username: proposal.proposer.email.split('@').first # Fallback if username not present
        },
        created_at: proposal.created_at
      }
    end
  end
end
