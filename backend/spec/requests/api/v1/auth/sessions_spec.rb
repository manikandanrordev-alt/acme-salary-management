require "rails_helper"

RSpec.describe "Api::V1::Auth::Sessions", type: :request do
  let!(:hr_user) do
    create(:user,
           email: "hr_director@acme.com",
           password: "SecurePassword123!",
           full_name: "Eleanor Vance",
           role: "hr_manager")
  end

  let!(:auditor_user) do
    create(:user,
           email: "compliance@acme.com",
           password: "AuditorPassword123!",
           full_name: "Marcus Aurelius",
           role: "auditor")
  end

  let!(:admin_user) do
    create(:user,
           email: "admin@acme.com",
           password: "AdminPassword123!",
           full_name: "System Admin",
           role: "admin")
  end

  describe "POST /api/v1/auth/login" do
    context "with valid credentials" do
      it "authenticates the user and sets session and CSRF cookies" do
        post "/api/v1/auth/login", params: {
          email: "hr_director@acme.com",
          password: "SecurePassword123!"
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"]["user"]["email"]).to eq("hr_director@acme.com")
        expect(json["data"]["user"]["role"]).to eq("hr_manager")
        expect(json["message"]).to eq("Logged in successfully")

        # Verify CSRF cookie is set
        expect(response.cookies["CSRF-TOKEN"]).to be_present
      end

      it "accepts nested params under { user: { ... } }" do
        post "/api/v1/auth/login", params: {
          user: {
            email: "hr_director@acme.com",
            password: "SecurePassword123!"
          }
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"]["user"]["email"]).to eq("hr_director@acme.com")
      end
    end

    context "with invalid password" do
      it "returns 401 Unauthorized with INVALID_CREDENTIALS code" do
        post "/api/v1/auth/login", params: {
          email: "hr_director@acme.com",
          password: "WrongPassword!"
        }

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("INVALID_CREDENTIALS")
        expect(json["error"]["message"]).to eq("Invalid email or password")
      end
    end

    context "with non-existent email" do
      it "returns 401 Unauthorized without disclosing user existence" do
        post "/api/v1/auth/login", params: {
          email: "nonexistent@acme.com",
          password: "AnyPassword123!"
        }

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("INVALID_CREDENTIALS")
      end
    end
  end

  describe "GET /api/v1/auth/me" do
    context "when authenticated" do
      it "returns the currently authenticated user's profile" do
        # Log in first
        post "/api/v1/auth/login", params: {
          email: "hr_director@acme.com",
          password: "SecurePassword123!"
        }
        expect(response).to have_http_status(:ok)

        # Retrieve current user
        get "/api/v1/auth/me"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"]["user"]["email"]).to eq("hr_director@acme.com")
        expect(json["data"]["user"]["full_name"]).to eq("Eleanor Vance")
        expect(json["data"]["user"]["role"]).to eq("hr_manager")
      end
    end

    context "when unauthenticated" do
      it "returns 401 Unauthorized" do
        get "/api/v1/auth/me"

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("UNAUTHORIZED")
        expect(json["error"]["message"]).to include("Authentication required")
      end
    end
  end

  describe "DELETE /api/v1/auth/logout" do
    it "logs the user out and terminates the session" do
      post "/api/v1/auth/login", params: {
        email: "hr_director@acme.com",
        password: "SecurePassword123!"
      }
      expect(response).to have_http_status(:ok)

      delete "/api/v1/auth/logout"
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("Logged out successfully")

      # Subsequent request to protected endpoint should fail
      get "/api/v1/auth/me"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/auth/csrf" do
    it "returns a valid CSRF token and sets CSRF-TOKEN cookie" do
      get "/api/v1/auth/csrf"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["csrf_token"]).to be_present
      expect(response.cookies["CSRF-TOKEN"]).to be_present
    end
  end

  describe "Role-Based Authorization (require_hr_manager!)" do
    context "when unauthenticated" do
      it "returns 401 Unauthorized" do
        get "/api/v1/auth/hr_only"
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("UNAUTHORIZED")
      end
    end

    context "when authenticated as HR Manager" do
      it "permits access with 200 OK" do
        post "/api/v1/auth/login", params: {
          email: "hr_director@acme.com",
          password: "SecurePassword123!"
        }
        expect(response).to have_http_status(:ok)

        get "/api/v1/auth/hr_only"
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["message"]).to eq("Authorized HR access granted")
      end
    end

    context "when authenticated as Admin" do
      it "permits access with 200 OK" do
        post "/api/v1/auth/login", params: {
          email: "admin@acme.com",
          password: "AdminPassword123!"
        }
        expect(response).to have_http_status(:ok)

        get "/api/v1/auth/hr_only"
        expect(response).to have_http_status(:ok)
      end
    end

    context "when authenticated as Auditor (non-HR/non-Admin)" do
      it "rejects access with 403 Forbidden" do
        post "/api/v1/auth/login", params: {
          email: "compliance@acme.com",
          password: "AuditorPassword123!"
        }
        expect(response).to have_http_status(:ok)

        get "/api/v1/auth/hr_only"
        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("FORBIDDEN")
        expect(json["error"]["message"]).to include("HR Manager authorization required")
      end
    end
  end
end
