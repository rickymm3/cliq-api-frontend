module Api
  class ModerationVotesController < BaseController
    before_action :authenticate_api_user!

    def create
      # Determine voteable
      voteable = if params[:post_id]
                   Post.find(params[:post_id])
                 elsif params[:reply_id]
                   Reply.find(params[:reply_id])
                 end

      unless voteable
        render json: { error: "Content not found" }, status: :not_found
        return
      end

      vote = ModerationVote.find_or_initialize_by(
        user: @current_user,
        voteable: voteable
      )
      
      # Handle both integer (0/1) and key (remove/keep) inputs
      vote.vote_type = params[:vote_type].to_i if params[:vote_type].to_s.match?(/^\d+$/)
      vote.vote_type = params[:vote_type] unless params[:vote_type].to_s.match?(/^\d+$/)

      if vote.save
        render json: { status: "success", message: "Vote recorded" }, status: :created
      else
        render json: { error: vote.errors.full_messages }, status: :unprocessable_entity
      end
    end
  end
end
