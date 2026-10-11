# frozen_string_literal: true

module Payroll
  class GratuityCalculator
    # Under the Payment of Gratuity Act, 1972:
    # Formula: (15 * Last Drawn Basic * Completed Years of Service) / 26
    # Vesting: Minimum 5 years of continuous service required (unless death/disability).
    # Maximum statutory tax-free cap: ₹20,00,000 (20 Lakhs).
    STATUTORY_CAP = 2_000_000.00
    DAYS_IN_MONTH = 26
    DAYS_FACTOR = 15

    def self.calculate(monthly_basic:, joining_date:, exit_date: Date.current, is_exempt_from_vesting: false)
      new(
        monthly_basic: monthly_basic,
        joining_date: joining_date,
        exit_date: exit_date,
        is_exempt_from_vesting: is_exempt_from_vesting
      ).calculate
    end

    def initialize(monthly_basic:, joining_date:, exit_date: Date.current, is_exempt_from_vesting: false)
      @monthly_basic = monthly_basic.to_f
      @joining_date = joining_date.is_a?(String) ? Date.parse(joining_date) : joining_date
      @exit_date = exit_date.is_a?(String) ? Date.parse(exit_date) : exit_date
      @is_exempt_from_vesting = is_exempt_from_vesting
    end

    def calculate
      tenure_in_days = (@exit_date - @joining_date).to_i
      raw_years = tenure_in_days / 365.25
      completed_years = (tenure_in_days / 365.25).floor
      fractional_days = tenure_in_days - (completed_years * 365.25)

      # Rounding rule: If remaining service is > 6 months (180 days), round up to next completed year
      effective_years = fractional_days > 180 ? completed_years + 1 : completed_years

      is_eligible = effective_years >= 5 || @is_exempt_from_vesting

      if is_eligible && effective_years.positive?
        computed_gratuity = ((DAYS_FACTOR * @monthly_basic * effective_years) / DAYS_IN_MONTH).round(2)
        final_gratuity = [ computed_gratuity, STATUTORY_CAP ].min
        tax_exempt_portion = final_gratuity
        taxable_portion = [ computed_gratuity - STATUTORY_CAP, 0.0 ].max
      else
        computed_gratuity = 0.0
        final_gratuity = 0.0
        tax_exempt_portion = 0.0
        taxable_portion = 0.0
      end

      # Monthly gratuity accrual liability provision for employer books = (15 / 26 / 12) * Basic ≈ 4.81%
      monthly_provision = ((DAYS_FACTOR.to_f / (DAYS_IN_MONTH * 12)) * @monthly_basic).round(2)

      {
        monthly_basic: @monthly_basic,
        joining_date: @joining_date.to_s,
        exit_date: @exit_date.to_s,
        tenure_days: tenure_in_days,
        tenure_years: raw_years.round(2),
        effective_completed_years: effective_years,
        is_vested: is_eligible,
        statutory_cap: STATUTORY_CAP,
        computed_amount: computed_gratuity,
        payable_amount: final_gratuity,
        tax_exempt_amount: tax_exempt_portion,
        taxable_amount: taxable_portion,
        monthly_liability_provision: monthly_provision,
        legal_reference: "Payment of Gratuity Act, 1972 (Sec 4(2))"
      }
    end

    # Leave encashment calculation: (Basic / 30) * unused earned leaves
    def self.calculate_leave_encashment(monthly_basic:, leave_days:, max_exemption: 2_500_000.00)
      basic_per_day = (monthly_basic.to_f / 30.0)
      gross_encashment = (basic_per_day * [ leave_days.to_f, 0.0 ].max).round(2)
      exempt_amount = [ gross_encashment, max_exemption ].min
      taxable_amount = [ gross_encashment - max_exemption, 0.0 ].max

      {
        monthly_basic: monthly_basic.to_f,
        leave_days: leave_days.to_f,
        daily_basic_rate: basic_per_day.round(2),
        gross_leave_encashment: gross_encashment,
        tax_exempt_amount: exempt_amount,
        taxable_amount: taxable_amount,
        statutory_exemption_limit: max_exemption,
        legal_reference: "CBDT Notification S.O. 2276(E) under Sec 10(10AA)"
      }
    end

    # Full & Final Settlement Suite
    def self.full_and_final_settlement(
      monthly_gross:,
      monthly_basic:,
      joining_date:,
      exit_date:,
      unpaid_days: 0,
      unused_leave_days: 0,
      notice_period_days: 60,
      notice_served_days: 60,
      diwali_bonus_accrued: 0,
      asset_damage_deductions: 0,
      tds_deduction: 0
    )
      # 1. Earned salary for unpaid days
      daily_gross = (monthly_gross.to_f / 30.0)
      earned_salary = (daily_gross * unpaid_days.to_f).round(2)

      # 2. Gratuity
      gratuity_res = calculate(
        monthly_basic: monthly_basic,
        joining_date: joining_date,
        exit_date: exit_date
      )

      # 3. Leave Encashment
      leave_res = calculate_leave_encashment(
        monthly_basic: monthly_basic,
        leave_days: unused_leave_days
      )

      # 4. Notice Period Shortfall Recovery
      notice_shortfall_days = [ notice_period_days.to_f - notice_served_days.to_f, 0.0 ].max
      notice_recovery = (daily_gross * notice_shortfall_days).round(2)

      # 5. Earnings total
      total_earnings = (earned_salary + gratuity_res[:payable_amount] + leave_res[:gross_leave_encashment] + diwali_bonus_accrued.to_f).round(2)

      # 6. Deductions total
      total_deductions = (notice_recovery + asset_damage_deductions.to_f + tds_deduction.to_f).round(2)

      # 7. Net settlement payable
      net_payable = (total_earnings - total_deductions).round(2)

      {
        settlement_summary: {
          total_earnings: total_earnings,
          total_deductions: total_deductions,
          net_payable: net_payable,
          status: net_payable >= 0 ? "PAYABLE_TO_EMPLOYEE" : "RECOVERABLE_FROM_EMPLOYEE"
        },
        earnings_breakdown: {
          earned_salary_for_unpaid_days: earned_salary,
          unpaid_days: unpaid_days,
          gratuity: gratuity_res,
          leave_encashment: leave_res,
          statutory_bonus_accrual: diwali_bonus_accrued.to_f
        },
        deductions_breakdown: {
          notice_shortfall_days: notice_shortfall_days,
          notice_recovery_amount: notice_recovery,
          asset_deductions: asset_damage_deductions.to_f,
          tds_deduction: tds_deduction.to_f
        }
      }
    end
  end
end
