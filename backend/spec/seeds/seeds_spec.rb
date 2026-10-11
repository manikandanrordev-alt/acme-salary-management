require "rails_helper"

RSpec.describe "Database Seed Verification", type: :model do
  before(:all) do
    # Execute deterministic seed in test database
    DatabaseCleaner.clean_with(:truncation)
    Rails.application.load_seed
  end

  after(:all) do
    DatabaseCleaner.clean_with(:truncation)
  end

  it "seeds exactly 10,000 employees" do
    expect(Employee.count).to eq(10_000)
  end

  it "seeds all 7 core departments" do
    expect(Department.count).to eq(7)
    expected_codes = %w[ENG PRD SAL MKT OPS FIN HR]
    expect(Department.pluck(:code)).to match_array(expected_codes)
  end

  it "seeds administrative, HR manager, and auditor users" do
    expect(User.count).to eq(5)
    hr_user = User.find_by(email: "hr_manager@acme.com")
    expect(hr_user).to be_present
    expect(hr_user.role).to eq("hr_manager")
    expect(hr_user.valid_password?("Password123!")).to be true

    hr_director = User.find_by(email: "hr_director@acme.com")
    expect(hr_director).to be_present
    expect(hr_director.valid_password?("Password123!")).to be true

    auditor = User.find_by(email: "auditor@acme.com")
    expect(auditor).to be_present
    expect(auditor.valid_password?("Password123!")).to be true

    compliance = User.find_by(email: "compliance@acme.com")
    expect(compliance).to be_present
    expect(compliance.valid_password?("Password123!")).to be true

    admin = User.find_by(email: "admin@acme.com")
    expect(admin).to be_present
    expect(admin.valid_password?("Password123!")).to be true
  end

  it "ensures every employee has exactly one active salary record" do
    active_salary_records_count = SalaryRecord.current.count
    expect(active_salary_records_count).to eq(10_000)
  end

  it "ensures all monetary amounts are positive decimals with 2 decimal places" do
    sample_salaries = SalaryRecord.limit(50).pluck(:amount)
    sample_salaries.each do |amt|
      expect(amt).to be > 0
      expect(amt.to_s).to match(/\A\d+(\.\d{1,2})?\z/)
    end
  end

  it "ensures all salary records use valid ISO-4217 currencies" do
    valid_currencies = %w[USD EUR GBP INR SGD]
    distinct_currencies = SalaryRecord.distinct.pluck(:currency)
    expect(distinct_currencies - valid_currencies).to be_empty
  end

  it "preserves non-overlapping effective dates for multi-period tenured employees" do
    multi_record_emp = Employee.joins(:salary_records)
                               .group("employees.id")
                               .having("COUNT(salary_records.id) > 1")
                               .first

    expect(multi_record_emp).to be_present
    records = multi_record_emp.salary_records.order(:effective_from)

    records.each_cons(2) do |prev_rec, next_rec|
      expect(prev_rec.effective_to).to be_present
      expect(next_rec.effective_from).to eq(prev_rec.effective_to + 1.day)
    end
  end

  it "verifies audit logs correspond with salary assignments" do
    expect(SalaryAuditLog.count).to eq(SalaryRecord.count)
    expect(SalaryAuditLog.where(action: "create").count).to be >= 10_000
  end

  it "verifies database constraints prevent orphan salary records" do
    expect {
      SalaryRecord.new(
        employee_id: 999_999,
        amount: 50_000,
        currency: "USD",
        effective_from: Date.current,
        pay_frequency: "annual",
        change_reason: "test"
      ).save!(validate: false)
    }.to raise_error(ActiveRecord::InvalidForeignKey)
  end
end
