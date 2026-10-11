require "rails_helper"

RSpec.describe Payroll::GratuityCalculator do
  describe ".calculate" do
    it "returns 0 if tenure is less than 5 years and not exempt" do
      result = described_class.calculate(
        monthly_basic: 50_000,
        joining_date: Date.current - 3.years,
        exit_date: Date.current
      )

      expect(result[:is_vested]).to be false
      expect(result[:payable_amount]).to eq(0.0)
    end

    it "calculates accurate statutory gratuity for 6 years of service under Payment of Gratuity Act" do
      # Formula: (15 * 50,000 * 6) / 26 = 4,500,000 / 26 = 173,076.92
      result = described_class.calculate(
        monthly_basic: 50_000,
        joining_date: Date.current - 6.years,
        exit_date: Date.current
      )

      expect(result[:is_vested]).to be true
      expect(result[:effective_completed_years]).to eq(6)
      expect(result[:payable_amount]).to eq(173_076.92)
      expect(result[:tax_exempt_amount]).to eq(173_076.92)
    end

    it "respects the statutory ₹20,00,000 cap" do
      # Very high basic: 2,50,000 per month for 30 years => (15 * 250000 * 30)/26 = 4,326,923.08
      result = described_class.calculate(
        monthly_basic: 250_000,
        joining_date: Date.current - 30.years,
        exit_date: Date.current
      )

      expect(result[:payable_amount]).to eq(2_000_000.0)
      expect(result[:taxable_amount]).to be > 0
    end
  end

  describe ".calculate_leave_encashment" do
    it "computes earned leave cashout at (Basic / 30) per day" do
      result = described_class.calculate_leave_encashment(
        monthly_basic: 60_000,
        leave_days: 15
      )

      # 60,000 / 30 = 2,000 per day * 15 days = 30,000
      expect(result[:gross_leave_encashment]).to eq(30_000.0)
      expect(result[:tax_exempt_amount]).to eq(30_000.0)
    end
  end

  describe ".full_and_final_settlement" do
    it "computes net settlement reconciling earnings, gratuity, leave encashment, and notice recovery" do
      settlement = described_class.full_and_final_settlement(
        monthly_gross: 80_000,
        monthly_basic: 40_000,
        joining_date: Date.current - 5.years,
        exit_date: Date.current,
        unpaid_days: 10,
        unused_leave_days: 12,
        notice_period_days: 60,
        notice_served_days: 60,
        diwali_bonus_accrued: 15_000,
        asset_damage_deductions: 2_000,
        tds_deduction: 5_000
      )

      summary = settlement[:settlement_summary]
      expect(summary[:status]).to eq("PAYABLE_TO_EMPLOYEE")
      expect(summary[:total_earnings]).to be > 100_000
      expect(summary[:total_deductions]).to eq(7_000.0)
      expect(summary[:net_payable]).to be > 0
    end
  end
end
