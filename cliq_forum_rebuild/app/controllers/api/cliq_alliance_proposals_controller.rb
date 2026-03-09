module Api
  class CliqAllianceProposalsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_cliq, only: [:create, :index]
    before_action :set_proposal, only: [:show, :vote]

    # GET /api/cliqs/:cliq_id/alliance_proposals
    def index
      # List proposals where the source is the current cliq (outgoing)
      # or where target is current cliq (incoming)?
      # Usually you view proposals *for* a cliq to vote on them.
      # If I am in Cliq A, I want to see proposals to ally with Cliq B.
      # The proposal is "Cliq A wants to ally with Cliq B".
      # Members of Cliq A vote on it? Or members of Cliq B?
      # For merges: Members of Source vote to merge into Target.
      # For Alliances: Members of Source (the one consuming the feed) vote to ally with Target.
      
      @proposals = @cliq.sent_alliance_proposals.includes(:target_cliq, :proposer)
      render json: @proposals.as_json(include: [:target_cliq, :proposer])
    end

    # POST /api/cliqs/:cliq_id/alliance_proposals
    def create
      # Safety Check for params (flat or nested)
      proposal_data = params[:proposal].present? ? params[:proposal] : params
      target_cliq_id = proposal_data[:target_cliq_id]
      description = proposal_data[:description]

      if target_cliq_id.blank?
        return render json: { errors: ["Target cliq is required"] }, status: :unprocessable_entity
      end

      # Find target cliq safely
      target_cliq = Cliq.find_by(id: target_cliq_id)
      
      unless target_cliq
        return render json: { errors: ["Target cliq not found"] }, status: :unprocessable_entity
      end

      if target_cliq.id == @cliq.id
        return render json: { errors: ["Cannot ally with self"] }, status: :unprocessable_entity
      end
      
      kind = (proposal_data[:kind].to_s == "disband_alliance") ? :disband_alliance : :create_alliance
      
      @proposal = @cliq.sent_alliance_proposals.build(
        target_cliq: target_cliq,
        proposer: current_user,
        description: description,
        status: :proposal_phase,
        kind: kind
      )

      if @proposal.save
        # Create a discussion post automatically
        action_verb = kind == :disband_alliance ? "dissolve the alliance" : "form an alliance"
        title_prefix = kind == :disband_alliance ? "Proposal: Disband Alliance with" : "Proposal: Ally with"
        
        post = Post.create!(
          cliq: @cliq,
          user: current_user,
          title: "#{title_prefix} #{target_cliq.name}",
          content: "<div>I propose we #{action_verb} with <a href='/cliqs/#{target_cliq.id}'>#{target_cliq.name}</a>.</div><div>#{description}</div>",
          kind: :alliance_proposal,
          cliq_alliance_proposal: @proposal
        )
        
        render json: @proposal, status: :created
      else
        render json: { errors: @proposal.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # GET /api/alliance_proposals/:id
    def show
      render json: @proposal.as_json(include: [:source_cliq, :target_cliq, :proposer, :votes, :post])
    end

    # POST /api/alliance_proposals/:id/vote
    def vote
      # Value should be true (yes) or false (no)
      value = params[:value]
      
      # Ensure user is a member of the source cliq?
      # Only subscribers should vote?
      unless @proposal.source_cliq.subscribers.exists?(id: current_user.id)
        # For now, maybe allow any user or restrict to subscribers.
        # Strict: return render json: { error: "Only subscribers can vote" }, status: :forbidden
      end

      begin
        @proposal.vote!(current_user, value)
        render json: { 
          status: "success", 
          yes_votes: @proposal.yes_votes, 
          no_votes: @proposal.no_votes,
          proposal_status: @proposal.status
        }
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.message }, status: :unprocessable_entity
      end
    end

    private

    def set_cliq
      @cliq = Cliq.find(params[:cliq_id])
    end

    def set_proposal
      @proposal = CliqAllianceProposal.find(params[:id])
    end
  end
end
