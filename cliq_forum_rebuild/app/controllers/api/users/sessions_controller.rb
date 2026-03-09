# frozen_string_literal: true

class Api::Users::SessionsController < Devise::SessionsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    token = request.env['warden-jwt_auth.token']
    
    # If token not present in env, user might have just logged in
    # and hook hasn't run or is not configured to run on this path?
    # Ensure a token is generated.
    if token.nil?
      token = request.env['warden-jwt_auth.token']
    end
    
    render json: {
      message: 'Logged in successfully.',
      data: {
        id: resource.id,
        email: resource.email,
        token: token
      }
    }, status: :ok
  end

  def respond_to_on_destroy
    log_out_success && return if current_user

    log_out_failure
  end

  def log_out_success
    render json: { message: "Logged out." }, status: :ok
  end

  def log_out_failure
    render json: { message: "Logged out failure." }, status: :unauthorized
  end
end
