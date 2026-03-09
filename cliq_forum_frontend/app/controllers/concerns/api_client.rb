module ApiClient
  extend ActiveSupport::Concern

  included do
    def api_base_url
      ENV.fetch('API_URL', 'http://localhost:3000') # API runs on 3000
    end

    def api_get(path, params = {}, options = {})
      url = "#{api_base_url}/api/#{path}"
      response = HTTParty.get(url, headers: auth_headers, query: params)
      Rails.logger.info("API GET #{url}: #{response.code} - #{response.body}")
      
      handle_auth_error(response) if response.code == 401 && !options[:skip_auth_check]
      
      begin
        JSON.parse(response.body)
      rescue JSON::ParserError => e
        Rails.logger.error("JSON Parse Error for #{url}: #{e.message}. Body: #{response.body[0..100]}...")
        { "error" => "Invalid response", "status" => response.code }
      end
    end

    def api_delete(path, params = {})
      url = "#{api_base_url}/api/#{path}"
      response = HTTParty.delete(url, headers: auth_headers, query: params)
      Rails.logger.info("API DELETE #{url}")

      if response.code == 401
        # handle_auth_error(response) 
        # Don't redirect immediately for API calls unless needed
      end
      
      begin
        JSON.parse(response.body)
      rescue JSON::ParserError => e
        Rails.logger.error("JSON Parse Error for #{url}: #{e.message}")
        { "error" => "Invalid response", "status" => response.code }
      end
    end

    def api_post(path, data, options = {})
      url = "#{api_base_url}/api/#{path}"
      headers = auth_headers.merge({ "Content-Type" => "application/json" })
      Rails.logger.info("API POST #{url}: #{data.inspect}")
      response = HTTParty.post(url, 
        body: data.to_json,
        headers: headers
      )
      Rails.logger.info("API POST Response #{url}: #{response.code} - #{response.body}")
      
      handle_auth_error(response) if response.code == 401 && !options[:skip_auth_check]
      
      begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        { "error" => "Invalid response", "status" => response.code }
      end
    end

    def api_patch(path, data, options = {})
      url = "#{api_base_url}/api/#{path}"
      headers = auth_headers.merge({ "Content-Type" => "application/json" })
      Rails.logger.info("API PATCH #{url}: #{data.inspect}")
      response = HTTParty.patch(url, 
        body: data.to_json,
        headers: headers
      )
      Rails.logger.info("API PATCH Response #{url}: #{response.code} - #{response.body}")
      
      handle_auth_error(response) if response.code == 401 && !options[:skip_auth_check]
      
      begin
        JSON.parse(response.body)
      rescue JSON::ParserError
        { "error" => "Invalid response", "status" => response.code }
      end
    end

    def api_put(path, data, options = {})
      url = "#{api_base_url}/api/#{path}"
      headers = auth_headers.merge({ "Content-Type" => "application/json" })
      Rails.logger.info("API PUT #{url}: #{data.inspect}")
      response = HTTParty.put(url, 
        body: data.to_json,
        headers: headers
      )
      Rails.logger.info("API PUT Response #{url}: #{response.code} - #{response.body}")
      
      handle_auth_error(response) if response.code == 401 && !options[:skip_auth_check]
      
      JSON.parse(response.body)
    end

    def api_delete_with_options(path, options = {})
      url = "#{api_base_url}/api/#{path}"
      headers = auth_headers.merge({ "Content-Type" => "application/json" })
      Rails.logger.info("API DELETE #{url}")
      response = HTTParty.delete(url, headers: headers)
      Rails.logger.info("API DELETE Response #{url}: #{response.code} - #{response.body}")
      
      handle_auth_error(response) if response.code == 401 && !options[:skip_auth_check]
      
      begin
        JSON.parse(response.body)
      rescue JSON::ParserError => e
        Rails.logger.error("JSON Parse Error for #{url}: #{e.message}. Body: #{response.body[0..100]}...")
        { "error" => "Invalid response", "status" => response.code }
      end
    end

    private

    def auth_headers
      token = session[:jwt_token]
      headers = {
        "X-Analytic-User-Ip" => request.remote_ip,
        "X-Analytic-User-Agent" => request.user_agent,
        "X-Forwarded-For" => request.remote_ip,
        "User-Agent" => request.user_agent
      }
      
      if token
        headers.merge!({
          "Authorization" => "Bearer #{token}",
          "HTTP_AUTHORIZATION" => "Bearer #{token}"
        })
      end

      Rails.logger.info("Auth headers: #{headers.inspect}, Token present: #{token.present?}")
      headers
    end

    def handle_auth_error(response)
      Rails.logger.warn("Auth error (#{response.code}): Token may have expired. Logging out.")
      
      # Clear session
      session[:jwt_token] = nil
      session[:user_id] = nil
      session[:user_email] = nil
      
      # Redirect to login with alert
      if request.format.json?
        # For JSON requests, just clear and let the frontend handle redirect
        return
      else
        redirect_to login_path, alert: "Your session has expired. Please log in again."
      end
    end
  end
end
