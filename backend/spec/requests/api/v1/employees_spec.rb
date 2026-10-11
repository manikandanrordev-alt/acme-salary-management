require "rails_helper"

RSpec.describe "Api::V1::Employees", type: :request do
  let!(:user) { create(:user, email: "hr_manager@acme.com", password: "Password123!", role: "hr_manager") }
  let!(:eng_dept) { create(:department, name: "Engineering", code: "ENG") }
  let!(:sales_dept) { create(:department, name: "Sales", code: "SAL") }

  let!(:emp1) do
    create(:employee,
           employee_code: "ACME-00101",
           first_name: "Alice",
           last_name: "Smith",
           email: "alice.smith@acme.com",
           department: eng_dept,
           country_code: "US",
           employment_status: "active",
           hire_date: Date.new(2022, 1, 15))
  end

  let!(:emp2) do
    create(:employee,
           employee_code: "ACME-00102",
           first_name: "Bob",
           last_name: "Jones",
           email: "bob.jones@acme.com",
           department: sales_dept,
           country_code: "GB",
           employment_status: "on_leave",
           hire_date: Date.new(2023, 6, 1))
  end

  let!(:emp3) do
    create(:employee,
           employee_code: "ACME-00103",
           first_name: "Charlie",
           last_name: "Brown",
           email: "charlie.brown@acme.com",
           department: eng_dept,
           country_code: "IN",
           employment_status: "terminated",
           hire_date: Date.new(2021, 3, 10),
           termination_date: Date.new(2024, 1, 1))
  end

  let!(:emp1_salary) do
    create(:salary_record,
           employee: emp1,
           amount: 110_000,
           currency: "USD",
           effective_from: Date.new(2022, 1, 15),
           effective_to: nil)
  end

  let!(:emp1_old_salary) do
    create(:salary_record,
           employee: emp1,
           amount: 90_000,
           currency: "USD",
           effective_from: Date.new(2021, 1, 15),
           effective_to: Date.new(2022, 1, 14))
  end

  def authenticate!
    post "/api/v1/auth/login", params: { email: user.email, password: "Password123!" }
    expect(response).to have_http_status(:ok)
  end

  describe "GET /api/v1/employees" do
    context "when unauthenticated" do
      it "returns 401 Unauthorized" do
        get "/api/v1/employees"
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("UNAUTHORIZED")
      end
    end

    context "when authenticated" do
      before { authenticate! }

      it "returns paginated employee records and metadata" do
        get "/api/v1/employees"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"]).to be_an(Array)
        expect(json["data"].size).to eq(3)
        expect(json["meta"]["total_count"]).to eq(3)
        expect(json["meta"]["page"]).to eq(1)
        expect(json["meta"]["per_page"]).to eq(25)
        expect(json["meta"]["total_pages"]).to eq(1)

        first_emp = json["data"].find { |e| e["id"] == emp1.id }
        expect(first_emp["employee_code"]).to eq("ACME-00101")
        expect(first_emp["full_name"]).to eq("Alice Smith")
        expect(first_emp["department"]["name"]).to eq("Engineering")
        expect(first_emp["current_salary"]["amount"]).to eq("110000.0")
        expect(first_emp["current_salary"]["currency"]).to eq("USD")
      end

      it "respects pagination parameters" do
        get "/api/v1/employees", params: { page: 1, per_page: 2 }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"].size).to eq(2)
        expect(json["meta"]["page"]).to eq(1)
        expect(json["meta"]["per_page"]).to eq(2)
        expect(json["meta"]["total_pages"]).to eq(2)
      end

      it "filters by search query across multiple fields (code, name, email)" do
        # Search by code
        get "/api/v1/employees", params: { search: "00101" }
        json = JSON.parse(response.body)
        expect(json["data"].size).to eq(1)
        expect(json["data"].first["employee_code"]).to eq("ACME-00101")

        # Search by first name
        get "/api/v1/employees", params: { search: "Alice" }
        json = JSON.parse(response.body)
        expect(json["data"].size).to eq(1)
        expect(json["data"].first["first_name"]).to eq("Alice")

        # Search by last name
        get "/api/v1/employees", params: { search: "Jones" }
        json = JSON.parse(response.body)
        expect(json["data"].size).to eq(1)
        expect(json["data"].first["last_name"]).to eq("Jones")

        # Search by email
        get "/api/v1/employees", params: { search: "charlie.brown" }
        json = JSON.parse(response.body)
        expect(json["data"].size).to eq(1)
        expect(json["data"].first["email"]).to eq("charlie.brown@acme.com")
      end

      it "filters by department_id" do
        get "/api/v1/employees", params: { department_id: eng_dept.id }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"].size).to eq(2)
        codes = json["data"].map { |e| e["employee_code"] }
        expect(codes).to contain_exactly("ACME-00101", "ACME-00103")
      end

      it "filters by country_code" do
        get "/api/v1/employees", params: { country_code: "GB" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"].size).to eq(1)
        expect(json["data"].first["employee_code"]).to eq("ACME-00102")
      end

      it "filters by employment_status" do
        get "/api/v1/employees", params: { employment_status: "terminated" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["data"].size).to eq(1)
        expect(json["data"].first["employee_code"]).to eq("ACME-00103")
      end

      it "sorts by hire_date desc" do
        get "/api/v1/employees", params: { sort_by: "hire_date", sort_order: "desc" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        codes = json["data"].map { |e| e["employee_code"] }
        expect(codes).to eq([ "ACME-00102", "ACME-00101", "ACME-00103" ])
      end

      it "sorts by name asc" do
        get "/api/v1/employees", params: { sort_by: "name", sort_order: "asc" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        codes = json["data"].map { |e| e["employee_code"] }
        # Brown, Jones, Smith
        expect(codes).to eq([ "ACME-00103", "ACME-00102", "ACME-00101" ])
      end
    end
  end

  describe "GET /api/v1/employees/:id" do
    context "when unauthenticated" do
      it "returns 401 Unauthorized" do
        get "/api/v1/employees/#{emp1.id}"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated" do
      before { authenticate! }

      it "returns full employee details including complete salary history" do
        get "/api/v1/employees/#{emp1.id}"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        data = json["data"]
        expect(data["id"]).to eq(emp1.id)
        expect(data["employee_code"]).to eq("ACME-00101")
        expect(data["department"]["name"]).to eq("Engineering")
        expect(data["current_salary"]["amount"]).to eq("110000.0")

        # Salary history timeline
        expect(data["salary_history"]).to be_an(Array)
        expect(data["salary_history"].size).to eq(2)
        history_amounts = data["salary_history"].map { |s| s["amount"] }
        expect(history_amounts).to eq([ "110000.0", "90000.0" ])
      end

      it "returns 404 Not Found with structured error for non-existent employee" do
        get "/api/v1/employees/999999"

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["error"]["code"]).to eq("NOT_FOUND")
        expect(json["error"]["message"]).to include("Employee not found with id 999999")
      end
    end
  end
end
