class ProfilesController < ApplicationController
  include ApiClient

  def show
    @user_id = params[:id]
    
    # Fetch user from API
    user_response = api_get("users/#{@user_id}")
    
    if user_response
      @user = user_response["id"] ? user_response : user_response["data"]
    else
      redirect_to root_path, alert: "User not found"
    end
  end

  def dashboard
    # Personal dashboard - only for logged-in user viewing their own profile
    if !logged_in?
      redirect_to login_path, alert: "You must be logged in"
      return
    end

    # Fetch current user's full profile with posts and subscriptions
    user_response = api_get("users/#{current_user[:id]}")
    
    # Check if user was found and valid
    if user_response && (user_response["id"] || user_response["data"])
      @user = user_response["id"] ? user_response : user_response["data"]
      @posts = @user["posts"] || []
      @subscriptions = @user["subscriptions"] || []
      @user_details = @user # Rename for clarity in view
    else
      # User data fetch failed - session is likely invalid (user deleted?)
      Rails.logger.warn("Dashboard load failed for user #{current_user[:id]}. Invalidating session.")
      session[:jwt_token] = nil
      session[:user_id] = nil
      session[:user_email] = nil
      @current_user = nil
      
      redirect_to login_path, alert: "Session invalid. Please log in again."
    end
  end

  def update
    unless logged_in?
      redirect_to login_path, alert: "You must be logged in"
      return
    end

    # Update User Settings
    # Map form params to API expected params
    user_params = {
      view_contentious_content: params[:view_contentious_content] == "1"
    }

    response = api_patch_user(current_user[:id], { user: user_params })

    if response && (response["id"] || (response["data"] && response["data"]["id"]))
      redirect_to dashboard_path, notice: "Preferences updated successfully."
    else
      redirect_to dashboard_path, alert: "Failed to update preferences."
    end
  end

  private

  def api_patch_user(id, data)
    api_patch("users/#{id}", data)
  end
end
