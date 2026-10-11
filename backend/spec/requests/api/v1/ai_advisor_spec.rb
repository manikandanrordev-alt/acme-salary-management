require "rails_helper"

RSpec.describe "Api::V1::AiAdvisor", type: :request do
  let!(:department) { Department.create!(name: "Engineering", code: "ENG") }
  let!(:employee) do
    Employee.create!(
      employee_code: "ACME-AI-01",
      first_name: "Pooja",
      last_name: "Sharma",
      email: "pooja.sharma@acme.com",
      department: department,
      country_code: "IN",
      employment_status: "active",
      hire_date: Date.new(2022, 6, 1)
    )
  end
  let!(:salary_record) do
    SalaryRecord.create!(
      employee: employee,
      amount: 1_800_000.0,
      currency: "INR",
      effective_from: Date.new(2022, 6, 1),
      pay_frequency: "annual",
      change_reason: "Initial offer"
    )
  end
  let!(:user) do
    User.create!(
      email: "hr_ai@acme.com",
      password: "Password123!",
      role: "hr_manager",
      full_name: "HR AI Manager"
    )
  end

  before do
    post "/api/v1/auth/login", params: { email: user.email, password: "Password123!" }, as: :json
  end

  describe "GET /api/v1/ai/summary" do
    it "returns AI payroll health score and benchmarks" do
      get "/api/v1/ai/summary"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"]["payroll_health_score"]).to be > 0
      expect(json["data"]["market_benchmarks"]).to have_key("ENG")
    end
  end

  describe "GET /api/v1/ai/attrition_risk" do
    it "returns attrition flight risk predictions" do
      get "/api/v1/ai/attrition_risk"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].size).to be >= 1
      expect(json["data"].first).to have_key("risk_level")
      expect(json["data"].first).to have_key("ai_recommendation")
    end
  end

  describe "POST /api/v1/ai/salary_recommendation" do
    it "generates tailored AI compensation revision suggestion" do
      post "/api/v1/ai/salary_recommendation", params: { employee_id: employee.id, performance_rating: 5 }, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"]["recommended_ctc_inr"]).to be > json["data"]["current_ctc_inr"]
      expect(json["data"]).to have_key("tax_impact")
      expect(json["data"]).to have_key("ai_rationale")
    end
  end
end
