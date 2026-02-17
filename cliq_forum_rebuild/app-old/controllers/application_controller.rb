class ApplicationController < ActionController::Base
  helper Pagy::Frontend
  before_action :set_page_cliq
  before_action :set_root_cliq
  before_action :initialize_cliqs
  before_action :store_user_location!, if: :storable_location?

  include Pagy::Backend
  include Pundit
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  def set_root_cliq
    @root_cliq = Cliq.root.first
    @categories = @root_cliq.child_cliqs
  end
  def set_page_cliq 
    @current_cliq = Cliq.first
  end

  private

  def storable_location?
    request.get? &&
      is_navigational_format? &&
      !devise_controller? &&
      !request.xhr?
  end

  def store_user_location!
    # Devise will pick this up
    store_location_for(:user, request.fullpath)
  end

  # Ensure post-auth flows always land on the homepage.
  def after_sign_in_path_for(_resource)
    root_path
  end

  # Redirect to the homepage after sign out as well.
  def after_sign_out_path_for(_resource_or_scope)
    root_path
  end

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to(request.referrer || root_path)
  end

  def initialize_cliqs
    @cliqs ||= []
  end
  
end
