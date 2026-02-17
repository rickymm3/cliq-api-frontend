class CliqsController < ApplicationController
  include ApiClient

  def show
    cliq_response = api_get("cliqs/#{params[:id]}")
    @cliq = cliq_response["data"] if cliq_response
    
    if @cliq.nil?
      redirect_to root_path, alert: "Cliq not found"
      return
    end
    
    @is_subscribed = @cliq["is_subscribed"]
    
    @parent_cliq = @cliq["parent"]
    @top_children_cliqs = @cliq["top_children"] || []
    @all_children_count = @cliq["all_children_count"] || 0
    @sibling_cliqs = @cliq["siblings"] || []
    
    query_params = {}
    query_params[:exclude_children] = "1" if params[:exclude_children] == "1"
    query_params[:page] = params[:page] || 1
    query_params[:limit] = 10 # Default
    
    posts_response = api_get("cliqs/#{params[:id]}/posts", query_params)
    @posts = posts_response["data"] || []
    @pagination = posts_response["pagination"] || {}
    
    if turbo_frame_request? && params[:page].to_i > 1
      render partial: "posts/list", locals: { posts: @posts, pagination: @pagination }
    end
  end

  def children
    cliq_response = api_get("cliqs/#{params[:id]}")
    @cliq = cliq_response["data"] if cliq_response
    
    if @cliq.nil?
      redirect_to root_path, alert: "Cliq not found"
      return
    end
    
    page = params[:page] || 1
    children_response = api_get("cliqs/#{params[:id]}/children", { page: page })
    @children = children_response["data"] || []
    @pagination = children_response["pagination"] || {}
  end

  def create_child
    # GET request - show the form
    cliq_response = api_get("cliqs/#{params[:id]}")
    @parent_cliq = cliq_response["data"] if cliq_response
    
    if @parent_cliq.nil?
      redirect_to root_path, alert: "Parent category not found"
      return
    end
    
    # Check if user is logged in
    if !logged_in?
      redirect_to login_path, alert: "You must be logged in to create a category"
      return
    end
  end

  def create_child_post
    # POST request - create the cliq and post
    parent_cliq_id = params[:id]
    
    if !logged_in?
      redirect_to login_path, alert: "You must be logged in"
      return
    end

    cliq_params = {
      name: params[:cliq][:name],
      description: params[:cliq][:description],
      parent_cliq_id: parent_cliq_id
    }

    # Create cliq via API
    cliq_response = api_post("cliqs", cliq_params)
    
    if cliq_response && cliq_response["data"]
      new_cliq = cliq_response["data"]
      
      # Now create post with the new cliq
      post_params = {
        title: params[:post][:title],
        content: params[:post][:content],
        post_type: params[:post][:post_type].to_i
      }
      
      post_response = api_post("cliqs/#{new_cliq["id"]}/posts", post_params)
      
      if post_response && post_response["data"]
        new_post = post_response["data"]
        redirect_to cliq_post_path(new_cliq["id"], new_post["id"]), notice: "Category and post created successfully!"
      else
        @errors = post_response&.dig("errors") || ["Failed to create post"]
        @parent_cliq = api_get("cliqs/#{parent_cliq_id}")&.dig("data") || { id: parent_cliq_id }
        render :create_child, status: :unprocessable_entity
      end
    else
      # Extract error messages from API response
      if cliq_response && cliq_response["status"]
        @errors = [cliq_response["status"]["message"]]
      else
        @errors = cliq_response&.dig("errors") || ["Failed to create cliq"]
      end
      @parent_cliq = api_get("cliqs/#{parent_cliq_id}")&.dig("data") || { id: parent_cliq_id }
      render :create_child, status: :unprocessable_entity
    end
  end

  def subscribe
    if !logged_in?
      redirect_to login_path, alert: "You must be logged in to subscribe"
      return
    end

    cliq_id = params[:id]
    
    # Call subscribe API
    api_response = api_post("cliqs/#{cliq_id}/subscribe", {})
    
    # If API response has data, subscription was successful
    @is_subscribed = api_response.present? && api_response["data"].present?
    
    # Render the partial directly. The turbo_frame_tag will handle the swap.
    render partial: "cliqs/subscribe_button", locals: { cliq_id: cliq_id, is_subscribed: @is_subscribed }
  end

  def unsubscribe
    if !logged_in?
      redirect_to login_path, alert: "You must be logged in to manage subscriptions"
      return
    end

    cliq_id = params[:id]
    
    # Call unsubscribe API
    api_response = api_delete("cliqs/#{cliq_id}/unsubscribe")
    
    # If API response has data, unsubscription was successful
    @is_subscribed = !(api_response.present? && api_response["data"].present?)
    
    # Render the partial directly. The turbo_frame_tag will handle the swap.
    render partial: "cliqs/subscribe_button", locals: { cliq_id: cliq_id, is_subscribed: @is_subscribed }
  end

end

