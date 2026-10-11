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
      expect(result[:tds_tax_deduction]).to eq(5_958.33)
      expect(result[:lop_deduction]).to eq(0.0)
      expect(result[:net_pay]).to be > 80_000.0
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
