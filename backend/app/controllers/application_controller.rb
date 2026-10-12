class ApplicationController < ActionController::API
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection

  protect_from_forgery with: :exception

  after_action :set_csrf_cookie

  rescue_from ActionController::InvalidAuthenticityToken do
    render json: {
      error: {
        code: "INVALID_CSRF",
        message: "Invalid or missing CSRF token"
      }
    }, status: :unprocessable_entity
  end

  def current_user
    @current_user ||= warden.user(:user)
  end

  def authenticate_user!
    return if current_user.present?

    render json: {
      error: {
        code: "UNAUTHORIZED",
        message: "Authentication required to access this resource"
      }
    }, status: :unauthorized
  end

  def require_hr_manager!
    authenticate_user!
    return if performed?

    unless current_user.hr_manager? || current_user.admin?
      render json: {
        error: {
          code: "FORBIDDEN",
          message: "HR Manager authorization required to perform this action"
        }
      }, status: :forbidden
    end
  end

  private

  def warden
    request.env["warden"]
  end

  def set_csrf_cookie
    csrf_same_site = Rails.env.production? ? ENV.fetch("SESSION_SAME_SITE", "none").to_sym : :lax
    cookies["CSRF-TOKEN"] = {
      value: form_authenticity_token,
      path: "/",
      same_site: csrf_same_site,
      secure: Rails.env.production?,
      httponly: false
    }
  end
end
