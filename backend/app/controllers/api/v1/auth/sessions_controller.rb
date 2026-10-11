module Api
  module V1
    module Auth
      class SessionsController < ApplicationController
        skip_before_action :verify_authenticity_token, only: [ :create, :destroy, :csrf_token ]
        before_action :authenticate_user!, only: [ :show, :destroy ]
        before_action :require_hr_manager!, only: [ :hr_only ]

        # POST /api/v1/auth/login
        def create
          email = login_params[:email]&.downcase&.strip
          password = login_params[:password]

          user = User.find_by(email: email)

          if user&.valid_password?(password)
            warden.set_user(user, scope: :user)
            render json: {
              data: {
                user: serialize_user(user)
              },
              message: "Logged in successfully"
            }, status: :ok
          else
            render json: {
              error: {
                code: "INVALID_CREDENTIALS",
                message: "Invalid email or password"
              }
            }, status: :unauthorized
          end
        end

        # DELETE /api/v1/auth/logout
        def destroy
          warden.logout(:user)
          reset_session
          render json: {
            message: "Logged out successfully"
          }, status: :ok
        end

        # GET /api/v1/auth/me
        def show
          render json: {
            data: {
              user: serialize_user(current_user)
            }
          }, status: :ok
        end

        # GET /api/v1/auth/hr_only (Tests HR role authorization)
        def hr_only
          render json: {
            message: "Authorized HR access granted"
          }, status: :ok
        end

        # GET /api/v1/auth/csrf
        def csrf_token
          render json: {
            csrf_token: form_authenticity_token
          }, status: :ok
        end

        private

        def login_params
          if params[:user].present?
            params.require(:user).permit(:email, :password)
          else
            params.permit(:email, :password)
          end
        end

        def serialize_user(user)
          {
            id: user.id,
            email: user.email,
            full_name: user.full_name,
            role: user.role,
            created_at: user.created_at
          }
        end
      end
    end
  end
end
