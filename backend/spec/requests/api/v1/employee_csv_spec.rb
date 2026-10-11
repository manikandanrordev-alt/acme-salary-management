require "rails_helper"

RSpec.describe "Api::V1::Employees CSV Export & Import", type: :request do
  let!(:hr_user) { create(:user, email: "hr_lead@acme.com", password: "Password123!", role: "hr_manager") }
  let!(:auditor_user) { create(:user, email: "auditor@acme.com", password: "Password123!", role: "auditor") }
  let!(:eng_dept) { create(:department, name: "Engineering", code: "ENG") }
  let!(:sales_dept) { create(:department, name: "Sales", code: "SAL") }

  let!(:existing_emp) do
    create(:employee,
           employee_code: "ACME-00001",
           first_name: "John",
           last_name: "Doe",
           email: "john.doe@acme.com",
           department: eng_dept,
           country_code: "US")
  end

  let!(:existing_salary) do
    create(:salary_record,
           employee: existing_emp,
           amount: 115_000,
           currency: "USD",
           effective_from: Date.new(2023, 1, 1),
           effective_to: nil)
  end

  def authenticate_as(u)
    post "/api/v1/auth/login", params: { email: u.email, password: "Password123!" }
    expect(response).to have_http_status(:ok)
  end

  describe "GET /api/v1/employees/export" do
    context "when unauthenticated" do
      it "returns 401 Unauthorized" do
        get "/api/v1/employees/export"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated" do
      before { authenticate_as(auditor_user) }

      it "exports CSV with correct headers and filtered rows" do
        get "/api/v1/employees/export"

        expect(response).to have_http_status(:ok)
        expect(response.headers["Content-Type"]).to include("text/csv")

        csv_rows = CSV.parse(response.body, headers: true)
        expect(csv_rows.headers).to include("employee_code", "current_salary", "currency", "department")

        match_row = csv_rows.find { |r| r["employee_code"] == "ACME-00001" }
        expect(match_row).to be_present
        expect(match_row["first_name"]).to eq("John")
        expect(match_row["current_salary"]).to eq("115000.0")
        expect(match_row["currency"]).to eq("USD")
      end
    end
  end

  describe "POST /api/v1/employees/import" do
    let(:valid_csv) do
      <<~CSV
        employee_code,first_name,last_name,email,department,country_code,employment_status,hire_date,current_salary,currency,pay_frequency
        ACME-90001,Jane,Austen,jane.austen@acme.com,Engineering,US,active,2024-01-10,135000,USD,annual
        ACME-90002,Arthur,Conan,arthur.conan@acme.com,Sales,GB,active,2024-02-15,85000,GBP,annual
      CSV
    end

    context "when unauthenticated" do
      it "returns 401 Unauthorized" do
        post "/api/v1/employees/import", params: { csv: valid_csv }
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated as non-HR auditor" do
      before { authenticate_as(auditor_user) }

      it "returns 403 Forbidden" do
        post "/api/v1/employees/import", params: { csv: valid_csv }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when authenticated as HR Manager" do
      before { authenticate_as(hr_user) }

      it "imports valid employee records, creates active salaries and audit trails" do
        expect {
          post "/api/v1/employees/import", params: { csv: valid_csv }
        }.to change(Employee, :count).by(2)
         .and change(SalaryRecord, :count).by(2)
         .and change(SalaryAuditLog, :count).by(2)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"]["created_count"]).to eq(2)
        expect(json["data"]["errors"]).to be_empty

        imported_emp = Employee.find_by(employee_code: "ACME-90001")
        expect(imported_emp.department).to eq(eng_dept)
        expect(imported_emp.salary_records.first.amount).to eq(135_000)
      end

      it "reports validation errors for invalid rows (e.g. duplicate code, invalid country)" do
        invalid_csv = <<~CSV
          employee_code,first_name,last_name,email,department,country_code,employment_status,hire_date,current_salary,currency,pay_frequency
          ACME-00001,Duplicate,Person,dup@acme.com,Engineering,US,active,2024-01-10,100000,USD,annual
          ACME-90003,Invalid,Country,country@acme.com,Engineering,XX,active,2024-01-10,100000,USD,annual
        CSV

        post "/api/v1/employees/import", params: { csv: invalid_csv }

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["data"]["created_count"]).to eq(0)
        expect(json["data"]["errors"].size).to eq(2)

        error_row2 = json["data"]["errors"].find { |e| e["row"] == 2 }
        expect(error_row2["errors"]).to include(match(/already taken/))

        error_row3 = json["data"]["errors"].find { |e| e["row"] == 3 }
        expect(error_row3["errors"]).to include(match(/Country code must be/))
      end
    end
  end
end
