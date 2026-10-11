Rails.application.routes.draw do
  devise_for :users, skip: [ :sessions, :registrations, :passwords ]

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      get "health", to: "health#show"

      namespace :auth do
        post "login", to: "sessions#create"
        delete "logout", to: "sessions#destroy"
        get "me", to: "sessions#show"
        get "csrf", to: "sessions#csrf_token"
        get "hr_only", to: "sessions#hr_only"
      end

      resources :employees, only: [ :index, :show ]
    end
  end
end
