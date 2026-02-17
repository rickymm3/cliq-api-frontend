require 'ostruct'

class PostsController < ApplicationController
  include ApiClient
  before_action :require_login, only: [:new, :create]

  def show
    @cliq_id = params[:cliq_id].to_i
    @post_id = params[:id].to_i
    
    @cliq = api_get("cliqs/#{@cliq_id}")["data"]
    @post = api_get("posts/#{@post_id}")["data"]
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
