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

      resources :departments, only: [ :index ]

      resources :employees, only: [ :index, :show ] do
        collection do
          get :export
          post :import
        end
        resources :salary_revisions, only: [ :create ]
      end

      get "analytics/summary", to: "analytics#summary"

      resources :payslips, only: [ :index, :show ] do
        collection do
          post :generate_batch
          post :send_batch_emails
        end
        member do
          post :send_email
        end
      end

      scope :ai, controller: :ai_advisor do
        get :summary
        get :attrition_risk
        get :anomalies
        post :salary_recommendation
      end

      scope :hr_suite, controller: :hr_suite do
        get :overview
        post :compare_tax
        post :calculate_fnf
        post :calculate_ctc
        get :appraisal_distribution
      end
    end
  end
end
