begin
  puts "Checking JWT Secret..."
  secret = Rails.application.credentials.devise_jwt_secret_key
  puts "Secret from credentials: #{secret.inspect}"
  
  fallback = 'your_jwt_secret_key_here'
  final_secret = secret || fallback
  puts "Final Secret: #{final_secret}"

  puts "Checking Warden::JWTAuth::UserEncoder..."
  user = User.first
  if user
    token, payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    puts "Generated Token: #{token}"
    puts "Payload: #{payload.inspect}"
    
    # Try to decode it
    decoded = JWT.decode(token, final_secret, true, algorithm: 'HS256')
    puts "Decoded successfully: #{decoded.inspect}"
  else
    puts "No user found to test."
  end
rescue => e
  puts "Error: #{e.class} - #{e.message}"
  puts e.backtrace
end
