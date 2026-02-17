class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include ApiClient
  include MediaHelper
  helper_method :current_user, :logged_in?
  helper_method :is_user_subscribed?

  before_action :set_sidebar_data

  private

  def current_user
    if logged_in?
      @current_user ||= { id: session[:user_id], email: session[:user_email] }
    else
      nil
    end
  end

  def logged_in?
    session[:jwt_token].present?
  end

  protected

  def set_sidebar_data
    response = api_get("cliqs")
    all_cliqs = response["data"] || []
    
    # Find the root cliq (the one with no parent)
    root_cliq = all_cliqs.find { |c| c["parent_cliq_id"].nil? }
    
    # Main cliqs for sidebar are direct children of root
    if root_cliq
      @main_cliqs = all_cliqs.select { |c| c["parent_cliq_id"] == root_cliq["id"] }
                             .sort_by { |c| c["rank"] || 0 }
    else
      @main_cliqs = []
    end
    
    # User subscriptions (if logged in)
    @user_subscriptions = []
    if logged_in? && current_user && current_user['id'].present?
      subscriptions_response = api_get("users/#{current_user['id']}/subscriptions")
      
      # If fetching subscriptions fails (e.g. user deleted), log them out
      if subscriptions_response.is_a?(Hash) && (subscriptions_response["error"] || subscriptions_response["status"] == 404)
        Rails.logger.warn("User #{current_user['id']} data fetch failed. Invalidating session.")
        session[:jwt_token] = nil
        session[:user_id] = nil
        session[:user_email] = nil
        @current_user = nil
      else
        @user_subscriptions = subscriptions_response["subscriptions"] || []
      end
    end
  end

  def is_user_subscribed?(cliq_id)
    @user_subscriptions.map { |sub| sub["cliq_id"] }.include?(cliq_id)
  end
end
