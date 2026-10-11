require "rails_helper"

RSpec.describe "Api::V1::Health", type: :request do
  describe "GET /api/v1/health" do
    it "returns HTTP 200 with ok status and db connected" do
      get "/api/v1/health"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("ok")
      expect(json["service"]).to eq("acme-salary-management-api")
      expect(json["db"]).to eq("connected")
      expect(json["timestamp"]).to be_present
    end
  end
end
