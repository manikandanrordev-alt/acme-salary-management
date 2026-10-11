require "rails_helper"

RSpec.describe "Api::V1::SalaryRevisions", type: :request do
  let!(:hr_user) { create(:user, email: "hr_admin@acme.com", password: "Password123!", role: "hr_manager") }
  let!(:auditor_user) { create(:user, email: "auditor_user@acme.com", password: "Password123!", role: "auditor") }
  let!(:department) { create(:department, name: "Engineering", code: "ENG") }
  let!(:employee) { create(:employee, department: department) }

  let!(:current_salary) do
    create(:salary_record,
           employee: employee,
           amount: 100_000,
           currency: "USD",
           effective_from: Date.new(2023, 1, 1),
           effective_to: nil)
  end

  def authenticate_as(u)
    post "/api/v1/auth/login", params: { email: u.email, password: "Password123!" }
    expect(response).to have_http_status(:ok)
  end

  describe "POST /api/v1/employees/:employee_id/salary_revisions" do
    let(:valid_params) do
      {
        amount: 115_000,
        currency: "USD",
        effective_from: "2024-01-01",
        change_reason: "annual_merit",
        pay_frequency: "annual"
      }
    end

    context "when unauthenticated" do
      it "returns 401 Unauthorized" do
        post "/api/v1/employees/#{employee.id}/salary_revisions", params: valid_params
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("UNAUTHORIZED")
      end
    end

    context "when authenticated as non-HR auditor" do
      before { authenticate_as(auditor_user) }

      it "returns 403 Forbidden" do
        post "/api/v1/employees/#{employee.id}/salary_revisions", params: valid_params
        expect(response).to have_http_status(:forbidden)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("FORBIDDEN")
      end
    end

    context "when authenticated as HR Manager" do
      before { authenticate_as(hr_user) }

      it "creates a new salary revision, closes previous record, and logs audit trail" do
        expect {
          post "/api/v1/employees/#{employee.id}/salary_revisions", params: valid_params
        }.to change(SalaryRecord, :count).by(1)
         .and change(SalaryAuditLog, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["message"]).to eq("Salary revision recorded successfully")
        expect(json["data"]["amount"]).to eq("115000.0")
        expect(json["data"]["currency"]).to eq("USD")
        expect(json["data"]["effective_from"]).to eq("2024-01-01")
        expect(json["data"]["effective_to"]).to be_nil

        # Verify old record was capped
        current_salary.reload
        expect(current_salary.effective_to).to eq(Date.new(2023, 12, 31))

        # Verify audit log details
        audit = SalaryAuditLog.last
        expect(audit.employee_id).to eq(employee.id)
        expect(audit.user_id).to eq(hr_user.id)
        expect(audit.action).to eq("update")
        expect(audit.previous_amount).to eq(100_000)
        expect(audit.new_amount).to eq(115_000)
        expect(audit.change_reason).to eq("annual_merit")
      end

      it "returns 422 Unprocessable Entity when effective_from date is in the past of active record" do
        post "/api/v1/employees/#{employee.id}/salary_revisions", params: valid_params.merge(effective_from: "2022-01-01")

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("REVISION_FAILED")
        expect(json["error"]["message"]).to match(/must be strictly after/)
      end

      it "returns 422 Unprocessable Entity when amount is zero or negative" do
        post "/api/v1/employees/#{employee.id}/salary_revisions", params: valid_params.merge(amount: -100)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("REVISION_FAILED")
        expect(json["error"]["message"]).to match(/greater than zero/)
      end

      it "returns 422 Unprocessable Entity when change_reason is missing" do
        post "/api/v1/employees/#{employee.id}/salary_revisions", params: valid_params.merge(change_reason: "")

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("REVISION_FAILED")
      end

      it "returns 404 Not Found when employee does not exist" do
        post "/api/v1/employees/99999999/salary_revisions", params: valid_params

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("NOT_FOUND")
      end
    end
  end
end
