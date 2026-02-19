module Api
  class CliqMergeProposalsController < BaseController
    include PostSerializable

    before_action :authenticate_api_user!
    before_action :set_source_cliq, only: [:create]

    # POST /api/cliqs/:cliq_id/merge_proposals
    def create
      # Check for nested extraction first, fallback to top-level
      proposal_params = params[:proposal] || {}
      target_cliq_id = proposal_params[:target_cliq_id] || params[:target_cliq_id]
      reason = proposal_params[:reason] || params[:reason]

      if target_cliq_id.blank?
        return render json: { status: "error", message: "Target Cliq is required" }, status: :unprocessable_entity
      end

      # Prevent proposing merge to self
      if @source_cliq.id.to_s == target_cliq_id.to_s
        return render json: { status: "error", message: "Cannot merge a cliq into itself" }, status: :unprocessable_entity
      end

      # Validates logic before calling service
      Rails.logger.info("Creating Merge Proposal: Source=#{@source_cliq.id}, Target=#{target_cliq_id}, Reason=#{reason}")

      service = MergeProposalService.new(current_user, @source_cliq.id, target_cliq_id, reason)
      result = service.call

      if result.is_a?(CliqMergeProposal) && result.persisted?
        # User requirement: "redirect to the new post."
        # In API, we return the post data so the frontend can redirect.
        post = result.post
        
        # Ensure post is loaded with associations if needed for serialization
        # post = Post.includes(:user, :cliq, :cliq_merge_proposal).find(post.id)

        render json: {
          status: "success",
          data: serialize_post(post, current_user),
          message: "Merge proposal created successfully"
        }, status: :created
      else
        error_messages = result.respond_to?(:errors) ? result.errors.full_messages : ["Unknown error"]
        Rails.logger.error("Merge Proposal Failed: #{error_messages}")
        render json: { 
          status: "error", 
          message: "Failed to create proposal: #{error_messages.join(', ')}", 
          errors: error_messages
        }, status: :unprocessable_entity
      end
    end

    # GET /api/merge_proposals/:id
    def show
      proposal = CliqMergeProposal.find(params[:id])
      render json: { status: "success", data: proposal }
    rescue ActiveRecord::RecordNotFound
      render json: { status: "error", message: "Proposal not found" }, status: :not_found
    end

    # POST /api/merge_proposals/:id/vote
    def vote
      proposal = CliqMergeProposal.find(params[:id])
      value = ActiveRecord::Type::Boolean.new.cast(params[:value])
      
      if value.nil?
        return render json: { status: "error", message: "Invalid vote value" }, status: :unprocessable_entity
      end

      begin
        proposal.vote!(current_user, value)
        render json: { 
          status: "success", 
          message: "Vote recorded",
          data: {
            yes_votes: proposal.yes_votes,
            no_votes: proposal.no_votes,
            status: proposal.status
          }
        }
      rescue ActiveRecord::RecordInvalid => e
        render json: { status: "error", message: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound
      render json: { status: "error", message: "Proposal not found" }, status: :not_found
    end

    private

    def set_source_cliq
      # Route is likely nested under cliqs: /api/cliqs/:cliq_id/merge_proposals
      @source_cliq = Cliq.find(params[:cliq_id])
    rescue ActiveRecord::RecordNotFound
      render json: { status: "error", message: "Cliq not found" }, status: :not_found
    end
  end
end
