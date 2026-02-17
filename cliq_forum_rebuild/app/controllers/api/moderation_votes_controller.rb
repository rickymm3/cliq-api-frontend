module Api
  class ModerationVotesController < BaseController
    before_action :authenticate_api_user!
    
    def create
      post = Post.find(params[:post_id])
      
      # Verify user is moderator
      unless current_user.moderated_cliqs.exists?(post.cliq_id)
        return render json: { status: "error", errors: ["Not authorized"] }, status: :forbidden
      end
      
      vote = current_user.moderation_votes.find_or_initialize_by(post: post)
      vote.vote_type = params[:vote_type] # "keep" (0) or "delete" (1)
      
      if vote.save
        check_consensus(post)
        render json: { status: "success", data: vote }
      else
        render json: { status: "error", errors: vote.errors.full_messages }, status: :unprocessable_entity
      end
    end
    
    private
    
    def check_consensus(post)
      # Simple consensus logic: 3 votes needed to decide
      votes = post.moderation_votes
      delete_votes = votes.where(vote_type: :delete).count
      keep_votes = votes.where(vote_type: :keep).count
      
      if delete_votes >= 3
        post.removed!
      elsif keep_votes >= 3
        post.visible!
        # Reset reports if kept? Optional.
        post.update(reports_count: 0) 
      end
    end
  end
end
