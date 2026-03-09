class ModerationVotesController < ApplicationController
  def create
    unless logged_in?
      redirect_to login_path, alert: "You must be logged in to vote."
      return
    end

    voteable_type = params[:type] || 'post' # 'post' or 'reply'
    voteable_id = params[:id]

    # Map to backend endpoint
    endpoint = if voteable_type == 'reply'
                 "replies/#{voteable_id}/moderation_vote"
               else
                 "posts/#{voteable_id}/moderation_vote"
               end

    # API Request
    # POST /api/posts/:id/moderation_vote OR /api/replies/:id/moderation_vote
    response = api_post(endpoint, { vote_type: params[:vote_type] })

    respond_to do |format|
      if response["status"] == "success" || response["status"] == "created"
        format.html { redirect_back fallback_location: root_path, notice: "Vote recorded." }
        format.turbo_stream { 
          # Replace the specific console instance
          render turbo_stream: turbo_stream.replace("democracy_console_#{voteable_type}_#{voteable_id}", partial: "shared/democracy_console_voted")
        }
      else
        format.html { redirect_back fallback_location: root_path, alert: "Vote failed: #{response['error']}" }
      end
    end
  end
end
