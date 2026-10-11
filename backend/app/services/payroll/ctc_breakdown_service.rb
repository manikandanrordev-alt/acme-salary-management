# frozen_string_literal: true

module Payroll
  class CtcBreakdownService
    # In Indian Corporate Total Rewards:
    # Annual CTC = Component A (Monthly Gross * 12) + Component B (Employer Retirals & Benefits) + Component C (Annual Bonus)
    #
    # Component A (Direct Remuneration):
    # - Basic Salary: 50% of Gross
    # - House Rent Allowance (HRA): 40% of Basic
    # - Conveyance Allowance: ₹19,200/yr (₹1,600/mo)
    # - Leave Travel Allowance (LTA): 5% of Basic
    # - Special Allowance: Balancing amount
    #
    # Component B (Employer Retiral Liabilities):
    # - Employer EPF (12% of Basic or statutory capped at ₹1,800/mo)
    # - Employer EPS (8.33% of Basic capped at ₹1,250/mo)
    # - Statutory Gratuity Provision Accrual (15/26/12 * Basic = 4.81% of Basic)
    # - Group Medical & Term Life Insurance (Fixed ₹18,000/yr)
    #
    # Component C (Statutory/Performance Bonus):
    # - Annual Diwali / Merit Bonus (8.33% to 20% of Basic)
    #
    # Net In-Hand / Take-Home:
    # Monthly Gross - Employee EPF (12%) - Professional Tax (₹200) - Monthly TDS

    INSURANCE_ANNUAL = 18_000.00
    CONVEYANCE_MONTHLY = 1_600.00
    PROFESSIONAL_TAX_MONTHLY = 200.00

    def self.calculate(annual_ctc:, bonus_percent: 8.33, pf_statutory_cap: true)
      new(annual_ctc: annual_ctc, bonus_percent: bonus_percent, pf_statutory_cap: pf_statutory_cap).calculate
    end

    def initialize(annual_ctc:, bonus_percent: 8.33, pf_statutory_cap: true)
      @annual_ctc = annual_ctc.to_f
      @bonus_percent = bonus_percent.to_f
      @pf_statutory_cap = pf_statutory_cap
    end

    def calculate
      # Employer benefits cost deduction to derive annual gross
      # Approx: Retirals & bonus form ~15-20% of CTC
      # Solving for Basic:
      # CTC = Gross*12 + Emp_PF*12 + Gratuity_accrual*12 + Insurance + (Basic * bonus_percent / 100)
      # Basic = 0.50 * Gross => Let gross_monthly = G, Basic = 0.5 * G
      # Monthly Retirals = (0.5 * G * 0.12) + (0.5 * G * 0.0481) = G * (0.06 + 0.02405) = 0.08405 * G
      # Annual Bonus = 0.5 * G * 12 * (bonus_percent / 100) = 6 * G * (bonus_percent / 100)
      # CTC = 12*G + 12*0.08405*G + 6*G*(bonus_percent/100) + INSURANCE_ANNUAL
      # G * (12 + 1.0086 + 6 * (bonus_percent/100)) = CTC - INSURANCE_ANNUAL

      effective_multiplier = 12.0 + (12.0 * 0.5 * 0.12) + (12.0 * 0.5 * (15.0 / (26.0 * 12.0))) + (12.0 * 0.5 * (@bonus_percent / 100.0))
      net_ctc_pool = [ @annual_ctc - INSURANCE_ANNUAL, 0.0 ].max
      monthly_gross = (net_ctc_pool / effective_multiplier).round(2)
      annual_gross = (monthly_gross * 12.0).round(2)

      # Component A: Direct Salary Elements
      monthly_basic = (monthly_gross * 0.50).round(2)
      annual_basic = (monthly_basic * 12.0).round(2)
      monthly_hra = (monthly_basic * 0.40).round(2)
      annual_hra = (monthly_hra * 12.0).round(2)
      monthly_conveyance = CONVEYANCE_MONTHLY
      annual_conveyance = (monthly_conveyance * 12.0).round(2)
      monthly_lta = (monthly_basic * 0.05).round(2)
      annual_lta = (monthly_lta * 12.0).round(2)

      monthly_special = [ monthly_gross - (monthly_basic + monthly_hra + monthly_conveyance + monthly_lta), 0.0 ].max.round(2)
      annual_special = (monthly_special * 12.0).round(2)

      # Component B: Employer Retirals & Benefits
      monthly_employer_pf = @pf_statutory_cap ? [ monthly_basic * 0.12, 1800.0 ].min.round(2) : (monthly_basic * 0.12).round(2)
      annual_employer_pf = (monthly_employer_pf * 12.0).round(2)

      monthly_gratuity_accrual = ((15.0 / (26.0 * 12.0)) * monthly_basic).round(2)
      annual_gratuity_accrual = (monthly_gratuity_accrual * 12.0).round(2)

      annual_insurance = INSURANCE_ANNUAL
      monthly_insurance = (annual_insurance / 12.0).round(2)

      component_b_annual = (annual_employer_pf + annual_gratuity_accrual + annual_insurance).round(2)

      # Component C: Annual Statutory / Performance Bonus
      annual_bonus = ((annual_basic * @bonus_percent) / 100.0).round(2)

      # Reconciled Total CTC
      total_calculated_ctc = (annual_gross + component_b_annual + annual_bonus).round(2)

      # Employee Deductions & Take Home
      monthly_employee_pf = monthly_employer_pf
      monthly_pt = PROFESSIONAL_TAX_MONTHLY
      tax_comp = TaxRegimeComparator.compare(annual_gross: annual_gross)
      monthly_tds = tax_comp[:new_regime][:monthly_tds]

      monthly_deductions = (monthly_employee_pf + monthly_pt + monthly_tds).round(2)
      monthly_net_take_home = (monthly_gross - monthly_deductions).round(2)
      annual_net_take_home = (monthly_net_take_home * 12.0).round(2)

      {
        annual_ctc: @annual_ctc,
        reconciled_ctc: total_calculated_ctc,
        component_a_gross: {
          title: "Component A: Monthly Direct Gross Salary",
          annual_total: annual_gross,
          monthly_total: monthly_gross,
          breakdown: {
            basic: { monthly: monthly_basic, annual: annual_basic, percentage: 50.0 },
            hra: { monthly: monthly_hra, annual: annual_hra, percentage: 20.0 },
            conveyance: { monthly: monthly_conveyance, annual: annual_conveyance },
            lta: { monthly: monthly_lta, annual: annual_lta, percentage: 2.5 },
            special_allowance: { monthly: monthly_special, annual: annual_special }
          }
        },
        component_b_retirals: {
          title: "Component B: Employer Retirals & Statutory Benefits",
          annual_total: component_b_annual,
          monthly_total: (component_b_annual / 12.0).round(2),
          breakdown: {
            employer_epf: { monthly: monthly_employer_pf, annual: annual_employer_pf, note: "12% of Basic (EPF + EPS)" },
            gratuity_accrual: { monthly: monthly_gratuity_accrual, annual: annual_gratuity_accrual, note: "4.81% Provision under Gratuity Act 1972" },
            group_mediclaim_insurance: { monthly: monthly_insurance, annual: annual_insurance, note: "Executive Health & Term Coverage" }
          }
        },
        component_c_bonus: {
          title: "Component C: Annual Statutory / Diwali Bonus",
          annual_total: annual_bonus,
          bonus_percent: @bonus_percent,
          note: "Payment of Bonus Act, 1965 (Disbursed during Diwali cycle)"
        },
        employee_take_home: {
          monthly_gross: monthly_gross,
          monthly_employee_pf: monthly_employee_pf,
          monthly_professional_tax: monthly_pt,
          monthly_estimated_tds: monthly_tds,
          monthly_total_deductions: monthly_deductions,
          monthly_net_in_hand: monthly_net_take_home,
          annual_net_in_hand: annual_net_take_home
        }
      }
    end
  end
end
