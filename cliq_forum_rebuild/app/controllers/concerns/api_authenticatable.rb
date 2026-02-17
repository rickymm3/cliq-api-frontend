module ApiAuthenticatable
  extend ActiveSupport::Concern

  def authenticate_api_user!
    Rails.logger.info("=== AUTH DEBUG ===")
    Rails.logger.info("All headers: #{request.headers.inspect}")
    Rails.logger.info("Authorization: #{request.headers['Authorization'].inspect}")
    Rails.logger.info("HTTP_AUTHORIZATION: #{request.headers['HTTP_AUTHORIZATION'].inspect}")
    
    header = request.headers['Authorization'] || request.headers['HTTP_AUTHORIZATION']
    Rails.logger.info("Selected header: #{header.inspect}")
    return render_unauthorized unless header

    begin
      token = header.split(' ').last
      decoded = JWT.decode(token, Rails.application.secret_key_base, true, { algorithm: 'HS256' })
      @current_user_id = decoded[0]['sub']
      @current_user = User.find(@current_user_id)
      Rails.logger.info("Auth successful: User #{@current_user_id}")
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
      decoded = JWT.decode(token, Rails.application.secret_key_base, true, { algorithm: 'HS256' })
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
