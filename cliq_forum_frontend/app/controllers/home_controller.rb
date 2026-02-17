class HomeController < ApplicationController
  include ApiClient
  before_action :set_sidebar_data, unless: -> { turbo_frame_request? && params[:page].present? }

  def index
    # Get trending/popular posts (Recent for now, as Main Feed)
    page = (params[:page] || 1).to_i
    limit = 10
    
    posts_response = api_get("posts?sort=recent&limit=#{limit}&page=#{page}")
    @recent_posts = posts_response["data"] || []
    @pagination = posts_response["pagination"] || {}

    if turbo_frame_request? && page > 1
      render partial: "posts/list", locals: { posts: @recent_posts, pagination: @pagination }
      return
    end
    
    # Get Hot Posts for Sidebar (only if not pagination request)
    hot_posts_limit = 5
    hot_posts_response = api_get("posts?sort=heat&limit=#{hot_posts_limit}")
    @hot_posts = hot_posts_response["data"] || []
    
    # Get Popular Cliqs for Sidebar
    popular_cliqs_response = api_get("cliqs?sort=popular&limit=5")
    @hot_cliqs = popular_cliqs_response["data"] || []
  end

  def explore
    # Placeholder for Explore All Cliqs feature (coming soon)
  end
end
