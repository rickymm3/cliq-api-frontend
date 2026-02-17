Rails.application.routes.draw do
  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    registration: 'signup'
  },
  controllers: {
    sessions: 'api/users/sessions',
    registrations: 'api/users/registrations'
  }
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    resources :users do
      post :sign_in, on: :collection
      get :subscribed_feed, on: :member
      get :following_feed, on: :member
      get :subscriptions, on: :member
      get :followers, on: :member
      get :following, on: :member
    end
    resources :search, only: [:index], controller: 'search'
    resources :cliqs do
      resources :posts
      get :children, on: :member
      get :search, on: :collection
      post :subscribe, on: :member
      delete :unsubscribe, on: :member
      resource :moderator_subscription, only: [:create, :destroy]
    end
    resources :posts do
      post :like, on: :member
      post :dislike, on: :member
      delete :unlike, on: :member
      post :signal, on: :member
      delete :unsignal, on: :member
      resources :replies, only: [:index, :create]
      resource :moderation_vote, only: [:create]
    end
    resources :replies, except: [:index, :create] do
      post :like, on: :member
      post :dislike, on: :member
      delete :unlike, on: :member
    end
    resources :direct_messages
    resources :direct_message_conversations
    resources :subscriptions
    resources :notifications
    resources :followed_users
    resources :moderator_roles
    resources :reports
  end
end
