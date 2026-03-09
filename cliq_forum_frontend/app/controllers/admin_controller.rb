class AdminController < ApplicationController
  before_action :require_admin

  def dashboard
    response = api_get("admin/dashboard")
    
    if response["status"] == "success"
      @data = response["data"]
      @merge_proposals = @data["merge_proposals"] || []
      @alliance_proposals = @data["alliance_proposals"] || []
      @stats = @data["stats"] || {}
    else
      flash[:alert] = "Failed to load dashboard: #{response['message']}"
      redirect_to root_path
    end
  end

  private

  def require_admin
    unless current_user && current_user[:admin]
      flash[:alert] = "Access Denied"
      redirect_to root_path
    end
  end
end
