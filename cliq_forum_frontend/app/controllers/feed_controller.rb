class FeedController < ApplicationController
  include ApiClient
  before_action :ensure_logged_in!

  def index
    page = (params[:page] || 1).to_i
    @feed_type = params[:type] || 'subscribed'
    
    endpoint = if @feed_type == 'following'
      "users/#{current_user[:id]}/following_feed"
    else
      "users/#{current_user[:id]}/subscribed_feed"
    end
    
    # Fetch feed from API
    response = api_get(endpoint, { page: page })
    
    # Fetch full user profile for sidebar stats
    user_response = api_get("users/#{current_user[:id]}")
    @user_profile = user_response["id"] ? user_response : user_response["data"]
    
    # Fetch following list for sidebar
    following_response = api_get("users/#{current_user[:id]}/following")
    @following = following_response["data"] || []
    
    if response.is_a?(Hash) && response["data"]
      @posts = response["data"]
      @pagination = response["pagination"] || {}
    else
      @posts = []
      @pagination = {}
    end

    if turbo_frame_request? && page > 1
      render partial: "posts/list", locals: { posts: @posts, pagination: @pagination }
    end
  end

  private

  def ensure_logged_in!
    redirect_to login_path unless logged_in?
  end
end
