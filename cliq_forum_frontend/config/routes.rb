Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  get "signup", to: "users#new"
  post "signup", to: "users#create"

  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"

  get "search", to: "search#index"
  get "feed", to: "feed#index"
  get "explore", to: "home#explore"

  resources :profiles, only: [:show]
  get "users/:id/profile", to: "profiles#show", as: :user_profile
  get "users/:id/followers", to: "users#followers", as: :user_followers
  get "users/:id/following", to: "users#following", as: :user_following
  get "my-profile", to: "profiles#dashboard", as: :dashboard

  resources :cliqs, only: [:show] do
    resources :posts, only: [:show, :new, :create] do
      resources :replies, only: [:create, :edit, :update, :destroy]
    end
    get :children, on: :member
    get :create_child, on: :member
    post :create_child, on: :member, action: :create_child_post
    post :subscribe, on: :member
    delete :unsubscribe, on: :member
  end
end
