module ApiAuthenticatable
  extend ActiveSupport::Concern

  def authenticate_api_user!
    
    header = request.headers['Authorization'] || request.headers['HTTP_AUTHORIZATION']
    return render_unauthorized unless header

    begin
      token = header.split(' ').last
      # Use same secret as Devise JWT config
      secret_key = Rails.application.credentials.devise_jwt_secret_key || Rails.application.secret_key_base
      decoded = JWT.decode(token, secret_key, true, { algorithm: 'HS256' })
      @current_user_id = decoded[0]['sub']
      @current_user = User.find(@current_user_id)
    rescue JWT::DecodeError, JWT::ExpiredSignature => e
      Rails.logger.info("JWT decode error: #{e.message}")
      render_unauthorized
    rescue StandardError => e
      Rails.logger.info("Auth error: #{e.message}")
      render_unauthorized
    end
  end

  def authenticate_api_user_optional!
    header = request.headers['Authorization'] || request.headers['HTTP_AUTHORIZATION']
    return unless header

    begin
      token = header.split(' ').last
      # Use same secret as Devise JWT config
      secret_key = Rails.application.credentials.devise_jwt_secret_key || Rails.application.secret_key_base
      decoded = JWT.decode(token, secret_key, true, { algorithm: 'HS256' })
      @current_user_id = decoded[0]['sub']
      @current_user = User.find(@current_user_id)
    rescue JWT::DecodeError, JWT::ExpiredSignature
      # Silently fail for optional auth
    rescue StandardError
      # Silently fail for optional auth
    end
  end

  def current_user
    @current_user
  end

  def render_unauthorized
    render json: { status: "error", message: "Unauthorized" }, status: :unauthorized
  end

  private

  def require_authentication
    authenticate_api_user!
  end
end
