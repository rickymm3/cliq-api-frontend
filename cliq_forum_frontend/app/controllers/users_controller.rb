class UsersController < ApplicationController
  include ApiClient

  def new
    # This action will render the registration form
  end

  def create
    data = {
      user: {
        email: params[:email],
        password: params[:password],
        password_confirmation: params[:password_confirmation]
      }
    }

    begin
      response = api_post("users", data)
      Rails.logger.info("API Response: #{response.inspect}")
      
      if response.is_a?(Hash) && response["data"] && response["data"]["id"]
        # Registration successful, store JWT if provided
        session[:jwt_token] = response["data"]["authentication_token"] if response["data"]["authentication_token"]
        session[:user_id] = response["data"]["id"]
        session[:user_email] = response["data"]["email"]
        redirect_to root_path, notice: "Successfully signed up!"
      elsif response.is_a?(Hash) && response["status"] && response["status"]["message"]
        flash[:alert] = response["status"]["message"]
        render :new
      else
        flash[:alert] = "Signup failed. Response: #{response.inspect}"
        render :new
      end
    rescue => e
      Rails.logger.error("Signup error: #{e.message}\n#{e.backtrace.join("\n")}")
      flash[:alert] = "An error occurred: #{e.message}"
      render :new
    end
  end

  def following
    @user_id = params[:id]
    response = api_get("users/#{@user_id}/following")
    @users = response["data"] || []
  end

  def followers
    @user_id = params[:id]
    response = api_get("users/#{@user_id}/followers")
    @users = response["data"] || []
  end
end
