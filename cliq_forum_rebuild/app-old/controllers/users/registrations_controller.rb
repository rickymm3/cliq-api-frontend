# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  # before_action :configure_sign_up_params, only: [:create]
  # before_action :configure_account_update_params, only: [:update]



  # If you need to customize other methods, you can do so here.
  # For instance, you might want to customize the paths after certain actions:

  def after_sign_up_path_for(resource)
    # Define the path where users are redirected after signing up
    # For example:
    root_path
  end

  def new
    build_resource({})
    resource.build_profile # This ensures a Profile object is created for the user
    respond_with resource
  end
  
  def create
    build_resource(sign_up_params)
  
    resource.build_profile unless resource.profile # Ensure profile is built
  
    if resource.save
      sign_up(resource_name, resource)
      respond_with resource, location: after_sign_up_path_for(resource)
    else
      render :new, status: :unprocessable_entity
    end
  end

  private 
  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation, profile_attributes: [:username])
  end

  def account_update_params
    params.require(:user).permit(:email, :password, :password_confirmation, :current_password, profile_attributes: [:username])
  end

end
