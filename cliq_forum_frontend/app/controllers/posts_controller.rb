require 'ostruct'

class PostsController < ApplicationController
  include ApiClient
  before_action :require_login, only: [:new, :create]

  def show
    @cliq_id = params[:cliq_id].to_i
    @post_id = params[:id].to_i
    
    # Fetch User Preference if logged in
    @view_contentious = false
    if logged_in?
      begin
        profile_data = api_get("users/#{current_user[:id]}/profile")
        if profile_data["status"] == "success"
          @view_contentious = profile_data["data"]["view_contentious_content"]
        end
      rescue => e
        Rails.logger.error "Failed to fetch user preference: #{e.message}"
      end
    end

    @cliq = api_get("cliqs/#{@cliq_id}")["data"]
    @post = api_get("posts/#{@post_id}")["data"]
    
    unless @cliq && @post
      redirect_to root_path, alert: "The content you are looking for could not be found."
      return
    end

    begin
      @replies = api_get("posts/#{@post_id}/replies")["data"] || []
    rescue
      @replies = []
    end
  end

  def new
    @cliq_id = params[:cliq_id].to_i
    @cliq = api_get("cliqs/#{@cliq_id}")["data"]
    # Initialize an empty OpenStruct so the form builder works
    @post = OpenStruct.new(title: nil, content: nil, post_type: 0)
  end

  def create
    @cliq_id = params[:cliq_id].to_i
    
    # Extract params to build the payload
    # Note: Using OpenStruct for @post to maintain state in the form on error
    form_params = params.require(:post).permit(:title, :content, :post_type)
    @post = OpenStruct.new(form_params.to_h)
    
    post_payload = {
      post: form_params.to_h
    }

    response = api_post("cliqs/#{@cliq_id}/posts", post_payload)

    if response["status"] == "success"
      # status: :see_other (303) is REQUIRED for Turbo form redirects
      redirect_to cliq_path(@cliq_id), notice: "Post created successfully!", status: :see_other
    else
      @cliq = api_get("cliqs/#{@cliq_id}")["data"]
      # @post is already set to preserve user input
      @errors = response["errors"] || ["Failed to create post"]
      # status: :unprocessable_entity (422) is REQUIRED for Turbo to render validation errors
      render :new, status: :unprocessable_entity
    end
  end

  private

  def require_login
    unless logged_in?
      redirect_to login_path, alert: "You must be logged in to create a post."
    end
  end
end
