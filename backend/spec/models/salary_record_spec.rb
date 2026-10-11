require "rails_helper"

RSpec.describe SalaryRecord, type: :model do
  let(:employee) { create(:employee) }

  describe "validations" do
    it "is valid with standard attributes" do
      record = build(:salary_record, employee: employee)
      expect(record).to be_valid
    end

    it "requires positive amount" do
      record = build(:salary_record, employee: employee, amount: -500)
      expect(record).not_to be_valid
      expect(record.errors[:amount]).to be_present
    end

    it "requires 3-letter uppercase currency" do
      record = build(:salary_record, employee: employee, currency: "usd")
      expect(record).not_to be_valid
      expect(record.errors[:currency]).to be_present
    end

    it "validates effective_to cannot precede effective_from" do
      record = build(:salary_record,
                     employee: employee,
                     effective_from: Date.new(2025, 1, 1),
                     effective_to: Date.new(2024, 12, 31))
      expect(record).not_to be_valid
      expect(record.errors[:effective_to]).to include("cannot precede effective_from date")
    end
  end

  describe "effective date overlap validation" do
    it "allows non-overlapping contiguous salary periods" do
      # Period 1
      create(:salary_record,
             employee: employee,
             effective_from: Date.new(2024, 1, 1),
             effective_to: Date.new(2024, 12, 31))

      # Period 2
      record2 = build(:salary_record,
                      employee: employee,
                      effective_from: Date.new(2025, 1, 1),
                      effective_to: nil)
      expect(record2).to be_valid
    end

    it "rejects overlapping salary periods with open-ended previous record" do
      create(:salary_record,
             employee: employee,
             effective_from: Date.new(2024, 1, 1),
             effective_to: nil)

      overlapping = build(:salary_record,
                          employee: employee,
                          effective_from: Date.new(2024, 6, 1),
                          effective_to: nil)
      expect(overlapping).not_to be_valid
      expect(overlapping.errors[:base]).to include("Salary effective date range overlaps with an existing record for this employee")
    end

    it "rejects overlapping closed date ranges" do
      create(:salary_record,
             employee: employee,
             effective_from: Date.new(2024, 1, 1),
             effective_to: Date.new(2024, 12, 31))

      overlapping = build(:salary_record,
                          employee: employee,
                          effective_from: Date.new(2024, 6, 1),
                          effective_to: Date.new(2025, 6, 1))
      expect(overlapping).not_to be_valid
      expect(overlapping.errors[:base]).to include("Salary effective date range overlaps with an existing record for this employee")
    end

    it "permits updating an existing record without self-overlap error" do
      record = create(:salary_record,
                      employee: employee,
                      effective_from: Date.new(2024, 1, 1),
                      effective_to: nil)

      record.amount = 120_000
      expect(record).to be_valid
      expect(record.save).to be true
    end
  end

  describe "scopes and methods" do
    it "filters current salary records accurately" do
      past = create(:salary_record,
                    employee: employee,
                    effective_from: Date.current - 2.years,
                    effective_to: Date.current - 1.year)

      current = create(:salary_record,
                       employee: employee,
                       effective_from: Date.current - 1.year + 1.day,
                       effective_to: nil)

      expect(described_class.current).to include(current)
      expect(described_class.current).not_to include(past)
      expect(current.current?).to be true
      expect(past.current?).to be false
    end
  end
end
