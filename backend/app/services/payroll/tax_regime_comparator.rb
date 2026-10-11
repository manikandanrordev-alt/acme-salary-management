# frozen_string_literal: true

module Payroll
  class TaxRegimeComparator
    # Indian Income Tax Slabs Comparison Engine:
    # FY 2024-25 / FY 2025-26
    # New Regime (Section 115BAC): Standard deduction ₹75,000; 87A rebate up to ₹7,00,000 taxable income.
    # Old Regime: Standard deduction ₹50,000; 80C up to ₹1.5L; 80D up to ₹25k/₹50k; HRA exemption; 87A rebate up to ₹5,00,000 taxable income.

    NEW_REGIME_STD_DEDUCTION = 75_000.00
    OLD_REGIME_STD_DEDUCTION = 50_000.00
    CESS_RATE = 0.04 # 4% Health & Education Cess

    def self.compare(annual_gross:, sec_80c: 150_000.00, sec_80d: 25_000.00, hra_exemption: 0.0, home_loan_interest: 0.0, nps_80ccd_1b: 0.0)
      new(
        annual_gross: annual_gross,
        sec_80c: sec_80c,
        sec_80d: sec_80d,
        hra_exemption: hra_exemption,
        home_loan_interest: home_loan_interest,
        nps_80ccd_1b: nps_80ccd_1b
      ).compare
    end

    def initialize(annual_gross:, sec_80c: 0.0, sec_80d: 0.0, hra_exemption: 0.0, home_loan_interest: 0.0, nps_80ccd_1b: 0.0)
      @annual_gross = annual_gross.to_f
      @sec_80c = [ sec_80c.to_f, 150_000.00 ].min # Capped at ₹1.5 Lakhs
      @sec_80d = [ sec_80d.to_f, 75_000.00 ].min  # Capped at ₹75k (Self + Senior Citizen parents)
      @hra_exemption = hra_exemption.to_f
      @home_loan_interest = [ home_loan_interest.to_f, 200_000.00 ].min # Capped at ₹2.0 Lakhs
      @nps_80ccd_1b = [ nps_80ccd_1b.to_f, 50_000.00 ].min # Capped at ₹50,000
    end

    def compare
      new_regime_result = calculate_new_regime
      old_regime_result = calculate_old_regime

      diff = (old_regime_result[:total_tax] - new_regime_result[:total_tax]).round(2)
      recommended = diff >= 0 ? "NEW_REGIME" : "OLD_REGIME"
      annual_savings = diff.abs
      monthly_savings = (annual_savings / 12.0).round(2)

      # Break-even deduction threshold calculation:
      # How much deductions would be required in Old Regime to beat New Regime?
      breakeven_deductions = calculate_breakeven_deductions

      {
        financial_year: IndiaTaxCalculator.current_financial_year,
        assessment_year: IndiaTaxCalculator.current_assessment_year,
        supported_financial_years: IndiaTaxCalculator::SUPPORTED_FINANCIAL_YEARS,
        annual_gross: @annual_gross,
        new_regime: new_regime_result,
        old_regime: old_regime_result,
        recommended_regime: recommended,
        annual_tax_difference: annual_savings,
        monthly_tax_savings: monthly_savings,
        summary_verdict: recommended == "NEW_REGIME" ?
          "New Tax Regime saves ₹#{annual_savings.to_i} annually (₹#{monthly_savings.to_i}/mo in take-home pay)" :
          "Old Tax Regime saves ₹#{annual_savings.to_i} annually due to substantial Chapter VI-A deductions",
        breakeven_deductions_required: breakeven_deductions
      }
    end

    private

    def calculate_new_regime
      taxable_income = [ @annual_gross - NEW_REGIME_STD_DEDUCTION, 0.0 ].max
      tax_before_cess = compute_new_regime_tax_slabs(taxable_income)

      # Section 87A Rebate & Marginal Relief under Finance Act:
      tax_after_rebate = if taxable_income <= 700_000.00
                           0.0
      else
                           excess_over_700k = taxable_income - 700_000.00
                           [ tax_before_cess, excess_over_700k ].min
      end
      cess = (tax_after_rebate * CESS_RATE).round(2)
      total_tax = (tax_after_rebate + cess).round(2)

      {
        regime: "NEW_REGIME",
        standard_deduction: NEW_REGIME_STD_DEDUCTION,
        total_deductions: NEW_REGIME_STD_DEDUCTION,
        taxable_income: taxable_income.round(2),
        tax_before_cess: tax_before_cess.round(2),
        cess: cess,
        total_tax: total_tax,
        effective_tax_rate: @annual_gross.positive? ? ((total_tax / @annual_gross) * 100).round(2) : 0.0,
        monthly_tds: (total_tax / 12.0).round(2),
        slabs_breakdown: [
          { slab: "Up to ₹3,00,000", rate: "0%", tax: 0 },
          { slab: "₹3,00,001 - ₹7,00,000", rate: "5%", tax: [ ([ taxable_income, 700_000 ].min - 300_000), 0 ].max * 0.05 },
          { slab: "₹7,00,001 - ₹10,00,000", rate: "10%", tax: [ ([ taxable_income, 1_000_000 ].min - 700_000), 0 ].max * 0.10 },
          { slab: "₹10,00,001 - ₹12,00,000", rate: "15%", tax: [ ([ taxable_income, 1_200_000 ].min - 1_000_000), 0 ].max * 0.15 },
          { slab: "₹12,00,001 - ₹15,00,000", rate: "20%", tax: [ ([ taxable_income, 1_500_000 ].min - 1_200_000), 0 ].max * 0.20 },
          { slab: "Above ₹15,00,000", rate: "30%", tax: [ taxable_income - 1_500_000, 0 ].max * 0.30 }
        ]
      }
    end

    def compute_new_regime_tax_slabs(income)
      return 0.0 if income <= 300_000

      tax = 0.0
      tax += [ income - 300_000, 400_000 ].min * 0.05 if income > 300_000
      tax += [ income - 700_000, 300_000 ].min * 0.10 if income > 700_000
      tax += [ income - 1_000_000, 200_000 ].min * 0.15 if income > 1_000_000
      tax += [ income - 1_200_000, 300_000 ].min * 0.20 if income > 1_200_000
      tax += (income - 1_500_000) * 0.30 if income > 1_500_000
      tax
    end

    def calculate_old_regime
      total_deductions = OLD_REGIME_STD_DEDUCTION + @sec_80c + @sec_80d + @hra_exemption + @home_loan_interest + @nps_80ccd_1b
      taxable_income = [ @annual_gross - total_deductions, 0.0 ].max
      tax_before_cess = compute_old_regime_tax_slabs(taxable_income)

      # Section 87A Rebate & Marginal Relief: Under Old Regime, if taxable income <= 5,00,000, tax is 0
      tax_after_rebate = if taxable_income <= 500_000.00
                           0.0
      else
                           excess_over_500k = taxable_income - 500_000.00
                           [ tax_before_cess, excess_over_500k ].min
      end
      cess = (tax_after_rebate * CESS_RATE).round(2)
      total_tax = (tax_after_rebate + cess).round(2)

      {
        regime: "OLD_REGIME",
        standard_deduction: OLD_REGIME_STD_DEDUCTION,
        sec_80c: @sec_80c,
        sec_80d: @sec_80d,
        hra_exemption: @hra_exemption,
        home_loan_interest: @home_loan_interest,
        nps_80ccd_1b: @nps_80ccd_1b,
        total_deductions: total_deductions.round(2),
        taxable_income: taxable_income.round(2),
        tax_before_cess: tax_before_cess.round(2),
        cess: cess,
        total_tax: total_tax,
        effective_tax_rate: @annual_gross.positive? ? ((total_tax / @annual_gross) * 100).round(2) : 0.0,
        monthly_tds: (total_tax / 12.0).round(2),
        slabs_breakdown: [
          { slab: "Up to ₹2,50,000", rate: "0%", tax: 0 },
          { slab: "₹2,50,001 - ₹5,00,000", rate: "5%", tax: [ ([ taxable_income, 500_000 ].min - 250_000), 0 ].max * 0.05 },
          { slab: "₹5,00,001 - ₹10,00,000", rate: "20%", tax: [ ([ taxable_income, 1_000_000 ].min - 500_000), 0 ].max * 0.20 },
          { slab: "Above ₹10,00,000", rate: "30%", tax: [ taxable_income - 1_000_000, 0 ].max * 0.30 }
        ]
      }
    end

    def compute_old_regime_tax_slabs(income)
      return 0.0 if income <= 250_000

      tax = 0.0
      tax += [ income - 250_000, 250_000 ].min * 0.05 if income > 250_000
      tax += [ income - 500_000, 500_000 ].min * 0.20 if income > 500_000
      tax += (income - 1_000_000) * 0.30 if income > 1_000_000
      tax
    end

    def calculate_breakeven_deductions
      # Approximate deductions required in Old Regime to match New Regime tax
      # In typical Indian payroll brackets (₹10L - ₹25L), breakeven requires ~₹3,75,000 to ₹4,25,000 in deductions
      if @annual_gross <= 750_000
        0.0
      elsif @annual_gross <= 1_200_000
        325_000.00
      elsif @annual_gross <= 1_500_000
        375_000.00
      else
        425_000.00
      end
    end
  end
end
