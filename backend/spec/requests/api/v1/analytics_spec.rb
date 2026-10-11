require "rails_helper"

RSpec.describe "Api::V1::Analytics", type: :request do
  let!(:user) { create(:user) }
  let!(:eng_dept) { create(:department, name: "Engineering", code: "ENG") }
  let!(:sales_dept) { create(:department, name: "Sales", code: "SAL") }

  let!(:emp_us_1) { create(:employee, department: eng_dept, country_code: "US") }
  let!(:emp_us_2) { create(:employee, department: eng_dept, country_code: "US") }
  let!(:emp_uk_1) { create(:employee, department: sales_dept, country_code: "GB") }

  before do
    # US employee 1: 100k USD active
    create(:salary_record, employee: emp_us_1, amount: 100_000, currency: "USD", effective_from: Date.new(2023, 1, 1), effective_to: nil)

    # US employee 2: 120k USD active
    create(:salary_record, employee: emp_us_2, amount: 120_000, currency: "USD", effective_from: Date.new(2023, 1, 1), effective_to: nil)

    # UK employee 1: 80k GBP active, plus old 60k GBP closed record (should NOT be counted in active payroll)
    create(:salary_record, employee: emp_uk_1, amount: 60_000, currency: "GBP", effective_from: Date.new(2021, 1, 1), effective_to: Date.new(2022, 12, 31))
    create(:salary_record, employee: emp_uk_1, amount: 80_000, currency: "GBP", effective_from: Date.new(2023, 1, 1), effective_to: nil)
  end

  describe "GET /api/v1/analytics/summary" do
    context "when unauthenticated" do
      it "returns 401 Unauthorized" do
        get "/api/v1/analytics/summary"
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when authenticated" do
      before do
        post "/api/v1/auth/login", params: { email: user.email, password: "Password123!" }
      end

      it "returns currency-partitioned compensation aggregates" do
        get "/api/v1/analytics/summary"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        data = json["data"]
        expect(data).to have_key("currencies")
        expect(data).to have_key("departments")
        expect(data).to have_key("countries")

        # Verify USD breakdown
        usd = data["currencies"].find { |c| c["currency"] == "USD" }
        expect(usd["headcount"]).to eq(2)
        expect(usd["total_payroll"]).to eq(220_000.0)
        expect(usd["average_salary"]).to eq(110_000.0)
        expect(usd["min_salary"]).to eq(100_000.0)
        expect(usd["max_salary"]).to eq(120_000.0)

        # Verify GBP breakdown (closed historical 60k record must NOT be counted)
        gbp = data["currencies"].find { |c| c["currency"] == "GBP" }
        expect(gbp["headcount"]).to eq(1)
        expect(gbp["total_payroll"]).to eq(80_000.0)
        expect(gbp["average_salary"]).to eq(80_000.0)

        # Verify currencies are separated (no cross-currency sum)
        expect(data["currencies"].size).to eq(2)
      end
    end
  end
end
