# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payroll::IndiaTaxCalculator do
  describe ".calculate - Year-Specific Statutory Rules" do
    it "determines active financial year as FY 2026-27 for current date (October 2026)" do
      res = described_class.calculate(1_000_000, date: Date.new(2026, 10, 11))

      expect(res[:financial_year]).to eq("FY 2026-27")
      expect(res[:assessment_year]).to eq("AY 2027-28")
      expect(res[:supported_financial_years]).to include("FY 2023-24", "FY 2024-25", "FY 2025-26", "FY 2026-27")
    end

    it "accurately resolves prior financial year FY 2024-25 for earlier dates" do
      res = described_class.calculate(1_000_000, date: Date.new(2025, 2, 1))

      expect(res[:financial_year]).to eq("FY 2024-25")
      expect(res[:assessment_year]).to eq("AY 2025-26")
    end

    it "applies FY 2023-24 statutory rules (₹50,000 standard deduction and 3L/6L/9L/12L/15L slabs)" do
      # In FY 2023-24, Standard Deduction was ₹50,000
      # Gross: 10,00,000 -> Std Ded: 50,000 -> Taxable: 9,50,000
      # Slabs: 0-3L (0) + 3-6L (3L @ 5% = 15,000) + 6-9L (3L @ 10% = 30,000) + 9-9.5L (50k @ 15% = 7,500)
      # Base Tax = 52,500
      # Cess 4% = 2,100
      # Total Tax = 54,600
      # Monthly TDS = 4,550.00
      res = described_class.calculate(1_000_000, financial_year: "FY 2023-24")

      expect(res[:financial_year]).to eq("FY 2023-24")
      expect(res[:assessment_year]).to eq("AY 2024-25")
      expect(res[:standard_deduction]).to eq(50_000.0)
      expect(res[:taxable_income]).to eq(950_000.0)
      expect(res[:base_tax]).to eq(52_500.0)
      expect(res[:cess]).to eq(2_100.0)
      expect(res[:total_annual_tax]).to eq(54_600.0)
      expect(res[:monthly_tds]).to eq(4_550.0)
    end

    it "applies FY 2024-25 / FY 2026-27 rules (₹75,000 standard deduction and 3L/7L/10L/12L/15L slabs)" do
      # In FY 2026-27, Standard Deduction is ₹75,000
      # Gross: 10,00,000 -> Std Ded: 75,000 -> Taxable: 9,25,000
      # Slabs: 0-3L (0) + 3-7L (4L @ 5% = 20,000) + 7-9.25L (2.25L @ 10% = 22,500)
      # Base Tax = 42,500
      # Cess 4% = 1,700
      # Total Tax = 44,200
      # Monthly TDS = 3,683.33
      res = described_class.calculate(1_000_000, financial_year: "FY 2026-27")

      expect(res[:financial_year]).to eq("FY 2026-27")
      expect(res[:assessment_year]).to eq("AY 2027-28")
      expect(res[:standard_deduction]).to eq(75_000.0)
      expect(res[:taxable_income]).to eq(925_000.0)
      expect(res[:base_tax]).to eq(42_500.0)
      expect(res[:cess]).to eq(1_700.0)
      expect(res[:total_annual_tax]).to eq(44_200.0)
      expect(res[:monthly_tds]).to eq(3_683.33)
    end
  end

  describe ".calculate - Zero and Negative Inputs" do
    it "handles zero gross salary safely without errors" do
      res = described_class.calculate(0)

      expect(res[:annual_gross]).to eq(0.0)
      expect(res[:standard_deduction]).to eq(0.0)
      expect(res[:taxable_income]).to eq(0.0)
      expect(res[:base_tax]).to eq(0.0)
      expect(res[:rebate_87a]).to eq(0.0)
      expect(res[:marginal_relief]).to eq(0.0)
      expect(res[:cess]).to eq(0.0)
      expect(res[:total_annual_tax]).to eq(0.0)
      expect(res[:monthly_tds]).to eq(0.0)
    end

    it "clamps negative salary input safely to zero" do
      res = described_class.calculate(-50_000)

      expect(res[:annual_gross]).to eq(0.0)
      expect(res[:standard_deduction]).to eq(0.0)
      expect(res[:taxable_income]).to eq(0.0)
      expect(res[:total_annual_tax]).to eq(0.0)
      expect(res[:monthly_tds]).to eq(0.0)
    end

    it "caps standard deduction to gross salary when salary is less than ₹75,000" do
      res = described_class.calculate(50_000)

      expect(res[:annual_gross]).to eq(50_000.0)
      expect(res[:standard_deduction]).to eq(50_000.0) # Cannot exceed gross
      expect(res[:taxable_income]).to eq(0.0)
      expect(res[:total_annual_tax]).to eq(0.0)
    end
  end

  describe ".calculate - Authoritative Boundaries & Rebate Proviso (FY 2026-27)" do
    it "applies zero tax for basic income of ₹3,00,000 within initial slab" do
      res = described_class.calculate(300_000)

      expect(res[:taxable_income]).to eq(225_000.0)
      expect(res[:total_annual_tax]).to eq(0.0)
    end

    it "applies zero tax for income up to ₹7,75,000 due to ₹75,000 standard deduction and Section 87A rebate" do
      # 7,75,000 - 75,000 std ded = 7,00,000 taxable. 87A rebate makes tax = 0
      res = described_class.calculate(775_000)

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

    it "correctly terminates marginal relief when normal slab tax is lower than excess income (e.g. ₹8,00,000)" do
      # Gross: 8,00,000 -> Taxable: 7,25,000 (Excess over 7L is ₹25,000)
      # Raw tax: 3L-7L (20,000) + 7L-7.25L (25k @ 10% = 2,500) = 22,500
      # Since Raw tax (22,500) < Excess income (25,000), normal slab tax applies without marginal relief
      # Cess 4% = 900; Total = 23,400
      res = described_class.calculate(800_000)

      expect(res[:taxable_income]).to eq(725_000.0)
      expect(res[:marginal_relief]).to eq(0.0)
      expect(res[:base_tax]).to eq(22_500.0)
      expect(res[:cess]).to eq(900.0)
      expect(res[:total_annual_tax]).to eq(23_400.0)
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
