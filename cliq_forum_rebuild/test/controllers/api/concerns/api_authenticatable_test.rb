require 'test_helper'

module Api
  class ApiAuthenticatableTest < ActionDispatch::IntegrationTest
    setup do
      @user = User.create!(email: 'test@example.com', password: 'password123', password_confirmation: 'password123')
      @other_user = User.create!(email: 'other@example.com', password: 'password123', password_confirmation: 'password123')
      
      # Get a valid JWT token
      login_response = post '/api/users/sign_in', params: {
        user: { email: @user.email, password: 'password123' }
      }
      @token = JSON.parse(response.body)['data']['authentication_token']
    end

    test 'requests without Authorization header are rejected' do
      post '/api/cliqs/1/posts', params: {
        post: { title: 'Test', content: 'Content' }
      }, as: :json

      assert_response :unauthorized
      assert_includes response.body, 'Unauthorized'
    end

    test 'requests with invalid token are rejected' do
      post '/api/cliqs/1/posts', params: {
        post: { title: 'Test', content: 'Content' }
      }, as: :json, headers: {
        'Authorization' => 'Bearer invalid_token_here'
      }

      assert_response :unauthorized
    end

    test 'requests with valid JWT token are authenticated' do
      cliq = Cliq.first || Cliq.create!(name: 'Test Cliq', description: 'Test')
      
      post "/api/cliqs/#{cliq.id}/posts", params: {
        post: { title: 'Test Post', content: 'Test content', post_type: 'discussion' }
      }, as: :json, headers: {
        'Authorization' => "Bearer #{@token}"
      }

      assert_response :created
      data = JSON.parse(response.body)['data']
      assert_equal @user.id, data['user']['id']
    end

    test 'token must have Bearer prefix' do
      cliq = Cliq.first || Cliq.create!(name: 'Test Cliq', description: 'Test')
      
      post "/api/cliqs/#{cliq.id}/posts", params: {
        post: { title: 'Test Post', content: 'Test content', post_type: 'discussion' }
      }, as: :json, headers: {
        'Authorization' => @token  # Missing "Bearer" prefix
      }

      assert_response :unauthorized
    end

    test 'optional authentication passes without token' do
      cliq = Cliq.first || Cliq.create!(name: 'Test Cliq', description: 'Test')
      
      get "/api/cliqs/#{cliq.id}/posts", as: :json

      assert_response :success
    end

    test 'optional authentication includes user if token provided' do
      cliq = Cliq.first || Cliq.create!(name: 'Test Cliq', description: 'Test')
      
      # Create a post so there's something to retrieve
      post "/api/cliqs/#{cliq.id}/posts", params: {
        post: { title: 'Test Post', content: 'Test content', post_type: 'discussion' }
      }, as: :json, headers: {
        'Authorization' => "Bearer #{@token}"
      }

      # Now retrieve with optional auth
      get "/api/cliqs/#{cliq.id}/posts", as: :json, headers: {
        'Authorization' => "Bearer #{@token}"
      }

      assert_response :success
    end
  end
end
