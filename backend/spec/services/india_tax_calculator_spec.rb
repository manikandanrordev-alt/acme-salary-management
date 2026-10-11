require "rails_helper"

RSpec.describe Payroll::IndiaTaxCalculator do
  describe ".calculate - Authoritative Rules (Finance (No. 2) Act, 2024 / FY 2024-25 & FY 2025-26)" do
    it "applies zero tax for income up to ₹7,75,000 due to ₹75,000 standard deduction and Section 87A rebate" do
      # 7,75,000 - 75,000 std ded = 7,00,000 taxable. 87A rebate makes tax = 0
      res = described_class.calculate(775_000)

      expect(res[:financial_year]).to eq("FY 2024-25 / FY 2025-26")
      expect(res[:standard_deduction]).to eq(75_000.0)
      expect(res[:taxable_income]).to eq(700_000.0)
      expect(res[:total_annual_tax]).to eq(0.0)
      expect(res[:monthly_tds]).to eq(0.0)
    end

    it "applies zero tax for gross income of ₹5,00,000" do
      res = described_class.calculate(500_000)

      expect(res[:taxable_income]).to eq(425_000.0)
      expect(res[:total_annual_tax]).to eq(0.0)
    end

    it "applies Section 87A marginal relief when income marginally exceeds ₹7,75,000 (e.g. ₹7,80,000)" do
      # Gross: 7,80,000 -> Taxable: 7,05,000 (Exceeds ₹7,00,000 by ₹5,000)
      # Without marginal relief: 3L-7L (4L @ 5%) = 20,000; 7L-7.05L (5k @ 10%) = 500 => Raw tax = 20,500
      # With Section 87A marginal relief proviso: Tax cannot exceed excess income (₹5,000)
      # Base tax = 5,000; Cess 4% = 200; Total = 5,200
      res = described_class.calculate(780_000)

      expect(res[:taxable_income]).to eq(705_000.0)
      expect(res[:marginal_relief]).to eq(15_500.0) # 20,500 - 5,000
      expect(res[:base_tax]).to eq(5_000.0)
      expect(res[:cess]).to eq(200.0)
      expect(res[:total_annual_tax]).to eq(5_200.0)
    end

    it "computes correct slab tax and cess for ₹10,00,000 annual CTC" do
      # Gross: 10,00,000 -> Taxable: 9,25,000
      # Slabs:
      # 0-3L: 0
      # 3-7L (4L @ 5%): 20,000
      # 7-9.25L (2.25L @ 10%): 22,500
      # Base Tax = 42,500
      # Cess 4% = 1,700
      # Total Tax = 44,200
      # Monthly TDS = 44,200 / 12 = 3,683.33
      res = described_class.calculate(1_000_000)

      expect(res[:taxable_income]).to eq(925_000.0)
      expect(res[:base_tax]).to eq(42_500.0)
      expect(res[:cess]).to eq(1_700.0)
      expect(res[:total_annual_tax]).to eq(44_200.0)
      expect(res[:monthly_tds]).to eq(3_683.33)
    end

    it "computes correct slab tax and 4% cess for ₹12,00,000 annual CTC" do
      # Gross: 12,00,000 -> Taxable: 11,25,000
      # Slabs:
      # 0-3L: 0
      # 3-7L (4L @ 5%): 20,000
      # 7-10L (3L @ 10%): 30,000
      # 10-11.25L (1.25L @ 15%): 18,750
      # Base Tax = 68,750
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

    it "computes correct slab tax for ₹15,75,000 annual CTC (exactly reaching 20% slab boundary)" do
      # Gross: 15,75,000 -> Taxable: 15,00,000
      # Slabs:
      # 0-3L: 0
      # 3-7L (4L @ 5%): 20,000
      # 7-10L (3L @ 10%): 30,000
      # 10-12L (2L @ 15%): 30,000
      # 12-15L (3L @ 20%): 60,000
      # Base Tax = 140,000
      # Cess 4% = 5,600
      # Total Tax = 145,600
      # Monthly TDS = 145,600 / 12 = 12,133.33
      res = described_class.calculate(1_575_000)

      expect(res[:taxable_income]).to eq(1_500_000.0)
      expect(res[:base_tax]).to eq(140_000.0)
      expect(res[:cess]).to eq(5_600.0)
      expect(res[:total_annual_tax]).to eq(145_600.0)
      expect(res[:monthly_tds]).to eq(12_133.33)
    end

    it "computes correct slab tax in the 30% top bracket for ₹20,00,000 annual CTC" do
      # Gross: 20,00,000 -> Taxable: 19,25,000
      # Base tax up to 15L = 140,000
      # Above 15L (4,25,000 @ 30%) = 127,500
      # Total Base Tax = 267,500
      # Cess 4% = 10,700
      # Total Tax = 278,200
      # Monthly TDS = 278,200 / 12 = 23,183.33
      res = described_class.calculate(2_000_000)

      expect(res[:taxable_income]).to eq(1_925_000.0)
      expect(res[:base_tax]).to eq(267_500.0)
      expect(res[:cess]).to eq(10_700.0)
      expect(res[:total_annual_tax]).to eq(278_200.0)
      expect(res[:monthly_tds]).to eq(23_183.33)
    end
  end
end
