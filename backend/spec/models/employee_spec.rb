require "rails_helper"

RSpec.describe Employee, type: :model do
  describe "validations" do
    subject { build(:employee) }

    it { is_expected.to be_valid }

    it "requires employee_code" do
      emp = build(:employee, employee_code: nil)
      expect(emp).not_to be_valid
    end

    it "validates uniqueness of employee_code" do
      create(:employee, employee_code: "ACME-00001")
      dup = build(:employee, employee_code: "ACME-00001")
      expect(dup).not_to be_valid
    end

    it "requires email" do
      emp = build(:employee, email: nil)
      expect(emp).not_to be_valid
    end

    it "validates uniqueness of email" do
      create(:employee, email: "john@acme.com")
      dup = build(:employee, email: "john@acme.com")
      expect(dup).not_to be_valid
    end

    it "validates country_code presence" do
      emp = build(:employee, country_code: nil)
      expect(emp).not_to be_valid
    end

    it "validates employment_status inclusion" do
      invalid = build(:employee, employment_status: "retired")
      expect(invalid).not_to be_valid
    end

    it "validates termination_date is not earlier than hire_date" do
      invalid = build(:employee, hire_date: Date.new(2024, 1, 1), termination_date: Date.new(2023, 12, 31))
      expect(invalid).not_to be_valid
      expect(invalid.errors[:termination_date]).to include("cannot precede hire date")
    end
  end

  describe "methods" do
    let(:employee) { create(:employee, first_name: "Bruce", last_name: "Wayne") }

    it "returns full name" do
      expect(employee.full_name).to eq("Bruce Wayne")
    end

    it "resolves current salary record" do
      # Historical record (effective 2 years ago, ended 1 year ago)
      create(:salary_record,
             employee: employee,
             amount: 80_000,
             effective_from: Date.current - 2.years,
             effective_to: Date.current - 1.year - 1.day)

      # Current active record
      current_record = create(:salary_record,
                              employee: employee,
                              amount: 100_000,
                              effective_from: Date.current - 1.year,
                              effective_to: nil)

      expect(employee.current_salary_record).to eq(current_record)
      expect(employee.current_salary_record.amount).to eq(100_000)
    end
  end
end
