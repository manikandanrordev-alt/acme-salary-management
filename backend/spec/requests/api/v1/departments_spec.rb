require "rails_helper"

RSpec.describe "Api::V1::Departments", type: :request do
  let!(:user) { create(:user) }
  let!(:dept1) { create(:department, name: "Engineering", code: "ENG") }
  let!(:dept2) { create(:department, name: "Finance", code: "FIN") }

  describe "GET /api/v1/departments" do
    context "when unauthenticated" do
      it "returns 401 Unauthorized" do
        get "/api/v1/departments"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated" do
      before do
        post "/api/v1/auth/login", params: { email: user.email, password: "Password123!" }
      end

      it "returns sorted department list" do
        get "/api/v1/departments"
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"].size).to eq(2)
        expect(json["data"].first["name"]).to eq("Engineering")
      end
    end
  end
end
