class SessionsController < ApplicationController
  include ApiClient

  def new
    # This action will render the login form
  end

  def create
    data = {
      user: {
        email: params[:email],
        password: params[:password]
      }
    }

    begin
      response = api_post("users/sign_in", data, skip_auth_check: true)
      Rails.logger.info("Login response: #{response.inspect}")
      
      if response["data"] && response["data"]["id"]
        # Login successful, store JWT token
        token = response["data"]["authentication_token"] || response["data"]["token"]
        Rails.logger.info("Storing JWT token: #{token.inspect}")
        session[:jwt_token] = token if token
        session[:user_id] = response["data"]["id"]
        session[:user_email] = response["data"]["email"]
        redirect_to root_path, notice: "Successfully logged in!"
      else
        # Use a more user-friendly error message
        flash.now[:alert] = "That username or password doesn't exist."
        render :new, status: :unprocessable_entity
      end
    rescue => e
      flash.now[:alert] = "An error occurred: #{e.message}"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    session[:jwt_token] = nil
    session[:user_id] = nil
    redirect_to root_path, notice: "Successfully logged out!"
  end
end
