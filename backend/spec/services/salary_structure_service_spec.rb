require "rails_helper"

RSpec.describe Payroll::SalaryStructureService do
  describe ".decompose" do
    it "decomposes annual CTC into Indian components with EPF, PT, and TDS" do
      result = described_class.decompose(1_200_000, working_days: 30, lop_days: 0)

      expect(result[:monthly_gross]).to eq(100_000.0)
      expect(result[:basic_pay]).to eq(50_000.0)
      expect(result[:hra]).to eq(20_000.0)
      expect(result[:special_allowance]).to eq(30_000.0)
      expect(result[:epf_deduction]).to eq(6_000.0) # 12% of basic
      expect(result[:pt_deduction]).to eq(200.0) # PT ₹200
      # Under FY 2026-27 statutory rules, taxable income on ₹12L CTC is ₹11.25L,
      # which is within the ₹12L Section 87A rebate ceiling resulting in ₹0 TDS
      expect(result[:tds_tax_deduction]).to eq(0.0)
      expect(result[:lop_deduction]).to eq(0.0)
      expect(result[:net_pay]).to be > 90_000.0
    end

    it "computes positive TDS for CTC exceeding the Section 87A rebate limit (e.g. ₹18,00,000 CTC)" do
      result = described_class.decompose(1_800_000)

      # Gross: 18L -> Taxable: 17.25L -> Annual Tax: 1,50,800 -> Monthly TDS: 12,566.67
      expect(result[:tds_tax_deduction]).to eq(12_566.67)
      expect(result[:net_pay]).to be > 100_000.0
    end

    it "applies Loss of Pay deduction for unpaid leave days" do
      result_with_lop = described_class.decompose(1_200_000, working_days: 30, lop_days: 2)
      expected_lop = ((100_000.0 / 30.0) * 2).round(2)

      expect(result_with_lop[:lop_deduction]).to eq(expected_lop)
      expect(result_with_lop[:paid_leaves]).to eq(28)
    end

    it "includes festive bonus in earnings when provided" do
      bonus = 25_000.0
      result = described_class.decompose(1_200_000, festive_bonus: bonus)

      expect(result[:diwali_bonus]).to eq(25_000.0)
      expect(result[:gross_earnings]).to eq(125_000.0)
    end
  end
end
