require "rails_helper"

RSpec.describe "Api::V1::HrSuite", type: :request do
  let!(:department) { Department.create!(name: "Finance", code: "FIN") }
  let!(:employee) do
    Employee.create!(
      employee_code: "ACME-HR-01",
      first_name: "Pooja",
      last_name: "Sharma",
      email: "pooja.sharma@acme.com",
      department: department,
      country_code: "IN",
      employment_status: "active",
      hire_date: Date.new(2020, 1, 15)
    )
  end
  let!(:salary_record) do
    SalaryRecord.create!(
      employee: employee,
      amount: 1_800_000.0,
      currency: "INR",
      effective_from: Date.new(2020, 1, 15),
      pay_frequency: "annual",
      change_reason: "Base compensation"
    )
  end
  let!(:hr_user) do
    User.create!(
      email: "chro@acme.com",
      password: "Password123!",
      role: "hr_manager",
      full_name: "Chief Human Resources Officer"
    )
  end

  before do
    post "/api/v1/auth/login", params: { email: hr_user.email, password: "Password123!" }, as: :json
  end

  describe "GET /api/v1/hr_suite/overview" do
    it "returns enterprise HR metrics and statutory compliance filings" do
      get "/api/v1/hr_suite/overview"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["metrics"]).to include("total_headcount", "monthly_wage_bill", "gratuity_reserve_liability", "statutory_compliance_rate")
      expect(json["statutory_filings"].size).to be >= 4
      expect(json["appraisal_cycle"]).to include("allocated_budget")
    end
  end

  describe "POST /api/v1/hr_suite/compare_tax" do
    it "compares New Regime vs Old Regime" do
      post "/api/v1/hr_suite/compare_tax", params: {
        annual_gross: 1_400_000,
        sec_80c: 150_000,
        sec_80d: 25_000,
        hra_exemption: 120_000
      }, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to include("new_regime", "old_regime", "recommended_regime", "annual_tax_difference")
    end
  end

  describe "POST /api/v1/hr_suite/calculate_fnf" do
    it "computes full and final settlement for an employee" do
      post "/api/v1/hr_suite/calculate_fnf", params: {
        employee_id: employee.id,
        unpaid_days: 10,
        unused_leave_days: 15,
        notice_period_days: 60,
        notice_served_days: 60
      }, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["settlement"]["settlement_summary"]).to include("net_payable", "status")
      expect(json["settlement"]["earnings_breakdown"]).to include("gratuity", "leave_encashment")
    end
  end

  describe "POST /api/v1/hr_suite/calculate_ctc" do
    it "generates Component A, B, and C breakdown" do
      post "/api/v1/hr_suite/calculate_ctc", params: {
        annual_ctc: 2_000_000,
        bonus_percent: 10.0
      }, as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to include("component_a_gross", "component_b_retirals", "component_c_bonus", "employee_take_home")
    end
  end

  describe "GET /api/v1/hr_suite/appraisal_distribution" do
    it "returns 5-tier bell curve distribution and merit pool budget" do
      get "/api/v1/hr_suite/appraisal_distribution"

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["bell_curve"].size).to eq(5)
      expect(json).to include("merit_pool_budget")
    end
  end
end
