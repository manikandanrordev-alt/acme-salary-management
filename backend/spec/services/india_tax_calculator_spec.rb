# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payroll::IndiaTaxCalculator do
  describe ".calculate - Year-Specific Statutory Rules" do
    it "determines active financial year as FY 2026-27 and tax year as Tax Year 2026-27 for current date (October 2026)" do
      res = described_class.calculate(1_000_000, date: Date.new(2026, 10, 11))

      expect(res[:financial_year]).to eq("FY 2026-27")
      expect(res[:tax_year]).to eq("Tax Year 2026-27")
      expect(res[:applicable_year]).to eq("Tax Year 2026-27")
      expect(res[:assessment_year]).to eq("Tax Year 2026-27")
      expect(res[:supported_financial_years]).to include("FY 2023-24", "FY 2024-25", "FY 2025-26", "FY 2026-27")
    end

    it "accurately resolves prior financial year FY 2024-25 for earlier dates" do
      res = described_class.calculate(1_000_000, date: Date.new(2025, 2, 1))

      expect(res[:financial_year]).to eq("FY 2024-25")
      expect(res[:applicable_year]).to eq("AY 2025-26")
      expect(res[:assessment_year]).to eq("AY 2025-26")
    end

    it "applies FY 2023-24 statutory rules (₹50k standard deduction and ₹3L/₹6L/₹9L/₹12L/₹15L slabs)" do
      # Gross: 10,00,000 -> Std Ded: 50,000 -> Taxable: 9,50,000
      # Slabs: 0-3L (0) + 3-6L (15,000) + 6-9L (30,000) + 9-9.5L (7,500) = 52,500
      # Cess 4% = 2,100 -> Total Tax = 54,600. Monthly TDS = 4,550.00
      res = described_class.calculate(1_000_000, financial_year: "FY 2023-24")

      expect(res[:financial_year]).to eq("FY 2023-24")
      expect(res[:applicable_year]).to eq("AY 2024-25")
      expect(res[:assessment_year]).to eq("AY 2024-25")
      expect(res[:standard_deduction]).to eq(50_000.0)
      expect(res[:taxable_income]).to eq(950_000.0)
      expect(res[:base_tax]).to eq(52_500.0)
      expect(res[:cess]).to eq(2_100.0)
      expect(res[:total_annual_tax]).to eq(54_600.0)
      expect(res[:monthly_tds]).to eq(4_550.0)
    end

    it "applies FY 2024-25 statutory rules (₹75k standard deduction and ₹3L/₹7L/₹10L/₹12L/₹15L slabs)" do
      # Gross: 10,00,000 -> Std Ded: 75,000 -> Taxable: 9,25,000
      # Slabs: 0-3L (0) + 3-7L (20,000) + 7-9.25L (22,500) = 42,500
      # Cess 4% = 1,700 -> Total Tax = 44,200. Monthly TDS = 3,683.33
      res = described_class.calculate(1_000_000, financial_year: "FY 2024-25")

      expect(res[:financial_year]).to eq("FY 2024-25")
      expect(res[:applicable_year]).to eq("AY 2025-26")
      expect(res[:assessment_year]).to eq("AY 2025-26")
      expect(res[:standard_deduction]).to eq(75_000.0)
      expect(res[:taxable_income]).to eq(925_000.0)
      expect(res[:base_tax]).to eq(42_500.0)
      expect(res[:cess]).to eq(1_700.0)
      expect(res[:total_annual_tax]).to eq(44_200.0)
      expect(res[:monthly_tds]).to eq(3_683.33)
    end

    it "applies FY 2025-26 & FY 2026-27 statutory rules with Tax Year 2026-27 terminology under Income-tax Act, 2025" do
      # Gross: 10,00,000 in FY 2026-27
      # Std Ded: 75,000 -> Taxable: 9,25,000
      # Under Income-tax Act, 2025: Tax Year 2026-27 is used, discontinuing legacy AY 2027-28
      # Since taxable <= ₹12,00,000, 87A rebate wipes entire tax (tax = 0)
      res = described_class.calculate(1_000_000, financial_year: "FY 2026-27")

      expect(res[:financial_year]).to eq("FY 2026-27")
      expect(res[:tax_year]).to eq("Tax Year 2026-27")
      expect(res[:applicable_year]).to eq("Tax Year 2026-27")
      expect(res[:assessment_year]).to eq("Tax Year 2026-27")
      expect(res[:standard_deduction]).to eq(75_000.0)
      expect(res[:taxable_income]).to eq(925_000.0)
      expect(res[:rebate_87a]).to eq(32_500.0) # 4-8L (20k) + 8-9.25L (12.5k)
      expect(res[:total_annual_tax]).to eq(0.0)
      expect(res[:monthly_tds]).to eq(0.0)
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
      expect(res[:standard_deduction]).to eq(50_000.0)
      expect(res[:taxable_income]).to eq(0.0)
      expect(res[:total_annual_tax]).to eq(0.0)
    end
  end

  describe ".calculate - Official Income Tax Department Guidance (AY 2026-27 / FY 2026-27)" do
    it "applies zero tax for basic income of ₹4,00,000 within initial slab" do
      res = described_class.calculate(400_000)

      expect(res[:standard_deduction]).to eq(75_000.0)
      expect(res[:taxable_income]).to eq(325_000.0)
      expect(res[:total_annual_tax]).to eq(0.0)
    end

    it "applies zero tax for income up to ₹12,75,000 due to ₹75,000 standard deduction and ₹12,00,000 87A rebate" do
      # Gross: 12,75,000 - 75,000 std ded = 12,00,000 taxable.
      # Slabs: 4-8L (20,000) + 8-12L (40,000) = 60,000 raw tax.
      # Section 87A full rebate wipes ₹60,000 -> Total Tax = 0.
      res = described_class.calculate(1_275_000)

      expect(res[:standard_deduction]).to eq(75_000.0)
      expect(res[:taxable_income]).to eq(1_200_000.0)
      expect(res[:rebate_87a]).to eq(60_000.0)
      expect(res[:total_annual_tax]).to eq(0.0)
      expect(res[:monthly_tds]).to eq(0.0)
    end

    it "applies Section 87A marginal relief when income marginally exceeds ₹12,75,000 (e.g. ₹12,85,000)" do
      # Gross: 12,85,000 -> Taxable: 12,10,000 (Exceeds ₹12,00,000 by ₹10,000)
      # Without marginal relief: 4L-8L (20k) + 8L-12L (40k) + 12L-12.1L (10k @ 15% = 1,500) = 61,500
      # With Section 87A marginal relief proviso: Tax cannot exceed excess income (₹10,000)
      # Base Tax = 10,000; Marginal Relief = 51,500 (61,500 - 10,000)
      # Cess 4% = 400; Total Tax = 10,400.00 (Monthly TDS: 866.67)
      res = described_class.calculate(1_285_000)

      expect(res[:taxable_income]).to eq(1_210_000.0)
      expect(res[:marginal_relief]).to eq(51_500.0)
      expect(res[:base_tax]).to eq(10_000.0)
      expect(res[:cess]).to eq(400.0)
      expect(res[:total_annual_tax]).to eq(10_400.0)
      expect(res[:monthly_tds]).to eq(866.67)
    end

    it "correctly terminates marginal relief when normal slab tax is lower than excess income (e.g. ₹14,00,000)" do
      # Gross: 14,00,000 -> Taxable: 13,25,000 (Excess over 12L is ₹1,25,000)
      # Raw tax: 4L-8L (20k) + 8L-12L (40k) + 12L-13.25L (1.25L @ 15% = 18,750) = 78,750
      # Since Raw tax (78,750) < Excess income (1,25,000), normal slab tax applies without marginal relief
      # Base Tax = 78,750; Cess 4% = 3,150; Total Tax = 81,900.00 (Monthly TDS: 6,825.00)
      res = described_class.calculate(1_400_000)

      expect(res[:taxable_income]).to eq(1_325_000.0)
      expect(res[:marginal_relief]).to eq(0.0)
      expect(res[:base_tax]).to eq(78_750.0)
      expect(res[:cess]).to eq(3_150.0)
      expect(res[:total_annual_tax]).to eq(81_900.0)
      expect(res[:monthly_tds]).to eq(6_825.0)
    end

    it "computes correct slab tax in the 16L-20L 20% slab for ₹18,00,000 annual CTC" do
      # Gross: 18,00,000 -> Taxable: 17,25,000
      # Slabs: 4-8L (20k) + 8-12L (40k) + 12-16L (60k) + 16-17.25L (1.25L @ 20% = 25k) = 1,45,000
      # Cess 4% = 5,800 -> Total Tax = 1,50,800.00 (Monthly TDS: 12,566.67)
      res = described_class.calculate(1_800_000)

      expect(res[:taxable_income]).to eq(1_725_000.0)
      expect(res[:base_tax]).to eq(145_000.0)
      expect(res[:cess]).to eq(5_800.0)
      expect(res[:total_annual_tax]).to eq(150_800.0)
      expect(res[:monthly_tds]).to eq(12_566.67)
    end

    it "computes correct slab tax at the 20L-24L 25% boundary for ₹20,75,000 annual CTC" do
      # Gross: 20,75,000 -> Taxable: 20,00,000
      # Slabs: 4-8L (20k) + 8-12L (40k) + 12-16L (60k) + 16-20L (80k) = 2,00,000
      # Cess 4% = 8,000 -> Total Tax = 2,08,000.00 (Monthly TDS: 17,333.33)
      res = described_class.calculate(2_075_000)

      expect(res[:taxable_income]).to eq(2_000_000.0)
      expect(res[:base_tax]).to eq(200_000.0)
      expect(res[:cess]).to eq(8_000.0)
      expect(res[:total_annual_tax]).to eq(208_000.0)
      expect(res[:monthly_tds]).to eq(17_333.33)
    end

    it "computes correct slab tax in the 30% top bracket for ₹26,00,000 annual CTC" do
      # Gross: 26,00,000 -> Taxable: 25,25,000
      # Slabs up to 24L: 20k + 40k + 60k + 80k + 100k = 3,00,000
      # Above 24L: (25,25,000 - 24,00,000 = 1,25,000) @ 30% = 37,500
      # Base Tax = 3,37,500; Cess 4% = 13,500 -> Total Tax = 3,51,000.00 (Monthly TDS: 29,250.00)
      res = described_class.calculate(2_600_000)

      expect(res[:taxable_income]).to eq(2_525_000.0)
      expect(res[:base_tax]).to eq(337_500.0)
      expect(res[:cess]).to eq(13_500.0)
      expect(res[:total_annual_tax]).to eq(351_000.0)
      expect(res[:monthly_tds]).to eq(29_250.0)
    end
  end
end
