require "rails_helper"

RSpec.describe Payroll::IndiaTaxCalculator do
  describe ".calculate" do
    it "applies zero tax for income up to ₹7,75,000 due to standard deduction and 87A rebate" do
      # 7,75,000 - 75,000 std ded = 7,00,000 taxable. 87A rebate makes tax = 0
      res = described_class.calculate(775_000)

      expect(res[:standard_deduction]).to eq(75_000.0)
      expect(res[:taxable_income]).to eq(700_000.0)
      expect(res[:total_annual_tax]).to eq(0.0)
      expect(res[:monthly_tds]).to eq(0.0)
    end

    it "computes correct slab tax and 4% cess for ₹12,00,000 annual CTC" do
      # Gross: 12,00,000
      # Std Ded: 75,000 -> Taxable: 11,25,000
      # Slabs:
      # 0-3L: 0
      # 3-7L (4L @ 5%): 20,000
      # 7-10L (3L @ 10%): 30,000
      # 10L-11.25L (1.25L @ 15%): 18,750
      # Base Tax = 20,000 + 30,000 + 18,750 = 68,750
      # Cess 4% = 2,750
      # Total Tax = 71,500
      # Monthly TDS = 71,500 / 12 = 5,958.33
      res = described_class.calculate(1_200_000)

      expect(res[:taxable_income]).to eq(1_125_000.0)
      expect(res[:base_tax]).to eq(68_750.0)
      expect(res[:cess]).to eq(2_750.0)
      expect(res[:total_annual_tax]).to eq(71_500.0)
      expect(res[:monthly_tds]).to eq(5_958.33)
    end
  end
end
