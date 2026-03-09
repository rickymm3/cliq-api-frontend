class CliqsController < ApplicationController
  include ApiClient
  
  # Skip potentially expensive sidebar data fetch for lightweight actions
  skip_before_action :set_sidebar_data, only: [:search]

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
    @allies_cliqs = @cliq["allies"] || []
    
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
    return if performed?

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
    return if performed?
    
    if cliq_response && cliq_response["data"]
      new_cliq = cliq_response["data"]
      
      # Now create post with the new cliq
      post_params = {
        title: params[:post][:title],
        content: params[:post][:content],
        post_type: params[:post][:post_type].to_i
      }
      
      post_response = api_post("cliqs/#{new_cliq["id"]}/posts", post_params)
      return if performed?
      
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
    
    respond_to do |format|
      format.html do
        if turbo_frame_request?
          render partial: "cliqs/subscribe_button", locals: { cliq_id: cliq_id, is_subscribed: @is_subscribed }
        else
          redirect_to cliq_path(cliq_id)
        end
      end
    end
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
    
    respond_to do |format|
      format.html do
        if turbo_frame_request?
          render partial: "cliqs/subscribe_button", locals: { cliq_id: cliq_id, is_subscribed: @is_subscribed }
        else
          redirect_to cliq_path(cliq_id)
        end
      end
    end
  end

  def search
    # GET /cliqs/search?q=query (Proxy to API)
    query = params[:q].to_s.strip
    per_page = (params[:per_page] || 20).to_i
    
    if query.blank?
      render json: { data: [] }
      return
    end
    
    # Forward the search request to API
    api_response = api_get("cliqs/search", { q: query, per_page: per_page })
    
    render json: api_response || { data: [] }
  end

  def create_merge_proposal
    # GET request - show the form to suggest a merge
    cliq_response = api_get("cliqs/#{params[:id]}")
    return if performed?

    @cliq = cliq_response["data"] if cliq_response
    
    if @cliq.nil?
      redirect_to root_path, alert: "Category not found"
      return
    end

    if !logged_in?
      redirect_to login_path, alert: "You must be logged in to propose a merge"
      return
    end
  end

  def submit_merge_proposal
    # POST request - submit the proposal
    cliq_id = params[:id]
    
    proposal_params = {
      target_cliq_id: params[:proposal][:target_cliq_id],
      reason: params[:proposal][:reason]
    }
    
    response = api_post("cliqs/#{cliq_id}/merge_proposals", { proposal: proposal_params })
    return if performed?
    
    if response && response["data"]
      redirect_to cliq_path(cliq_id), notice: "Merge proposal submitted for community voting!"
    else
      @errors = response&.dig("errors") || ["Failed to submit proposal"]
      @cliq = api_get("cliqs/#{cliq_id}")&.dig("data")
      render :create_merge_proposal, status: :unprocessable_entity
    end
  end

  def create_alliance_proposal
    # GET request - show the form to suggest an alliance
    cliq_response = api_get("cliqs/#{params[:id]}")
    return if performed?

    @cliq = cliq_response["data"] if cliq_response
    
    if @cliq.nil?
      redirect_to root_path, alert: "Category not found"
      return
    end

    if !logged_in?
      redirect_to login_path, alert: "You must be logged in to propose an alliance"
      return
    end
  end

  def submit_alliance_proposal
    # POST request - submit the proposal
    cliq_id = params[:id]
    
    # We are proposing FOR @cliq (source) to ally WITH target_cliq (target)
    proposal_params = {
      target_cliq_id: params[:proposal][:target_cliq_id],
      description: params[:proposal][:description]
    }
    
    # Start Alliance Proposal for this Cliq
    response = api_post("cliqs/#{cliq_id}/alliance_proposals", proposal_params)
    return if performed?
    
    if response && (response["status"] == "created" || response["id"])
      redirect_to cliq_path(cliq_id), notice: "Alliance proposal submitted for community voting!"
    else
      @errors = response&.dig("errors") || ["Failed to submit proposal"]
      @cliq = api_get("cliqs/#{cliq_id}")&.dig("data")
      render :create_alliance_proposal, status: :unprocessable_entity
    end
  end

  def submit_disband_proposal
    response = api_post("cliqs/#{params[:id]}/alliance_proposals", {
      proposal: {
        target_cliq_id: params[:ally_id],
        kind: "disband_alliance",
        description: "Vote to dissolve alliance"
      }
    })
    
    if response && (response["status"] == "created" || response["id"])
      redirect_to cliq_path(params[:id]), notice: "Proposal to disband alliance submitted for community vote."
    else
      redirect_to cliq_path(params[:id]), alert: (response&.dig("errors") || []).first || "Failed to submit disband proposal."
    end
  end
end

