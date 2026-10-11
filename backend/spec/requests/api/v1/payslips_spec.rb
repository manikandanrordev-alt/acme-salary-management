require "rails_helper"

RSpec.describe "Api::V1::Payslips", type: :request do
  let!(:department) { Department.create!(name: "Engineering", code: "ENG") }
  let!(:employee) do
    Employee.create!(
      employee_code: "ACME-PAY-01",
      first_name: "Aarav",
      last_name: "Patel",
      email: "aarav.patel@acme.com",
      department: department,
      country_code: "IN",
      employment_status: "active",
      hire_date: Date.new(2023, 1, 15)
    )
  end
  let!(:salary_record) do
    SalaryRecord.create!(
      employee: employee,
      amount: 1_200_000.0,
      currency: "INR",
      effective_from: Date.new(2023, 1, 15),
      pay_frequency: "annual",
      change_reason: "Initial offer"
    )
  end
  let!(:hr_user) do
    User.create!(
      email: "hr_lead@acme.com",
      password: "Password123!",
      role: "hr_manager",
      full_name: "HR Lead"
    )
  end

  before do
    post "/api/v1/auth/login", params: { email: hr_user.email, password: "Password123!" }, as: :json
  end

  describe "POST /api/v1/payslips/generate_batch" do
    it "generates payslips for active employees" do
      post "/api/v1/payslips/generate_batch", params: { payroll_month: "2026-10", include_diwali_bonus: true }, as: :json

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["data"]["generated_count"]).to be >= 1

      payslip = Payslip.find_by(employee: employee, payroll_month: "2026-10")
      expect(payslip).to be_present
      expect(payslip.currency).to eq("INR")
      expect(payslip.diwali_bonus).to be > 0
      expect(payslip.net_pay).to be > 0
    end
  end

  describe "GET /api/v1/payslips" do
    before do
      Payroll::PayslipGenerator.generate_for_employee(employee, payroll_month: "2026-10")
    end

    it "lists payslips with summary metrics" do
      get "/api/v1/payslips", params: { payroll_month: "2026-10" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].size).to be >= 1
      expect(json["summary"]["total_payslips"]).to be >= 1
      expect(json["summary"]["total_net_disbursed_inr"]).to be > 0
    end
  end

  describe "POST /api/v1/payslips/:id/send_email" do
    let!(:payslip) { Payroll::PayslipGenerator.generate_for_employee(employee, payroll_month: "2026-10") }

    it "sends email and marks payslip as dispatched" do
      expect {
        post "/api/v1/payslips/#{payslip.id}/send_email", as: :json
      }.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(response).to have_http_status(:ok)
      payslip.reload
      expect(payslip.status).to eq("dispatched")
      expect(payslip.email_recipient).to eq(employee.email)
    end
  end
end
