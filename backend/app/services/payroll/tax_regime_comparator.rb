# frozen_string_literal: true

module Payroll
  class TaxRegimeComparator
    # Indian Income Tax Slabs Comparison Engine:
    # Compares New Regime (Section 115BAC) vs Old Regime with Chapter VI-A deductions.
    # Dynamically adapts to the specified or current financial year.

    OLD_REGIME_STD_DEDUCTION = 50_000.00
    CESS_RATE = 0.04 # 4% Health & Education Cess

    def self.compare(annual_gross:, sec_80c: 150_000.00, sec_80d: 25_000.00, hra_exemption: 0.0, home_loan_interest: 0.0, nps_80ccd_1b: 0.0, financial_year: nil, date: Date.current)
      new(
        annual_gross: annual_gross,
        sec_80c: sec_80c,
        sec_80d: sec_80d,
        hra_exemption: hra_exemption,
        home_loan_interest: home_loan_interest,
        nps_80ccd_1b: nps_80ccd_1b,
        financial_year: financial_year,
        date: date
      ).compare
    end

    def initialize(annual_gross:, sec_80c: 0.0, sec_80d: 0.0, hra_exemption: 0.0, home_loan_interest: 0.0, nps_80ccd_1b: 0.0, financial_year: nil, date: Date.current)
      @annual_gross = [ annual_gross.to_f, 0.0 ].max
      @date = date || Date.current
      @financial_year = financial_year || IndiaTaxCalculator.current_financial_year(@date)

      # Statutory Chapter VI-A Deduction Caps:
      @sec_80c = [ sec_80c.to_f, 150_000.00 ].min # Capped at ₹1.5 Lakhs
      @sec_80d = [ sec_80d.to_f, 75_000.00 ].min  # Capped at ₹75k (Self + Senior Citizen parents)
      @hra_exemption = [ hra_exemption.to_f, 0.0 ].max
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

      breakeven_deductions = calculate_breakeven_deductions

      {
        financial_year: @financial_year,
        assessment_year: IndiaTaxCalculator.current_assessment_year(@date),
        supported_financial_years: IndiaTaxCalculator::SUPPORTED_FINANCIAL_YEARS,
        annual_gross: @annual_gross,
        new_regime: new_regime_result,
        old_regime: old_regime_result,
        recommended_regime: recommended,
        annual_tax_difference: annual_savings,
        monthly_tax_savings: monthly_savings,
        summary_verdict: generate_verdict(recommended, annual_savings, monthly_savings),
        breakeven_deductions_required: breakeven_deductions
      }
    end

    private

    def generate_verdict(recommended, annual_savings, monthly_savings)
      if annual_savings.zero?
        "Both Tax Regimes yield identical zero tax liability under statutory threshold"
      elsif recommended == "NEW_REGIME"
        "New Tax Regime saves ₹#{annual_savings.to_i} annually (₹#{monthly_savings.to_i}/mo in take-home pay)"
      else
        "Old Tax Regime saves ₹#{annual_savings.to_i} annually due to substantial Chapter VI-A deductions"
      end
    end

    def calculate_new_regime
      calc = IndiaTaxCalculator.new(@annual_gross, date: @date, financial_year: @financial_year).calculate

      slabs_breakdown = calc_slabs_breakdown(calc[:taxable_income])

      {
        regime: "NEW_REGIME",
        standard_deduction: calc[:standard_deduction],
        total_deductions: calc[:standard_deduction],
        taxable_income: calc[:taxable_income],
        tax_before_cess: calc[:base_tax],
        marginal_relief: calc[:marginal_relief],
        cess: calc[:cess],
        total_tax: calc[:total_annual_tax],
        effective_tax_rate: @annual_gross.positive? ? ((calc[:total_annual_tax] / @annual_gross) * 100).round(2) : 0.0,
        monthly_tds: calc[:monthly_tds],
        slabs_breakdown: slabs_breakdown
      }
    end

    def calc_slabs_breakdown(taxable_income)
      rules = IndiaTaxCalculator::YEAR_RULES[@financial_year] || IndiaTaxCalculator::YEAR_RULES[IndiaTaxCalculator::FINANCIAL_YEAR]
      previous_limit = 0.0

      rules[:slabs].map do |slab|
        current_limit = slab[:limit]
        rate_percent = (slab[:rate] * 100).to_i

        taxable_in_slab = if taxable_income <= previous_limit
                            0.0
        elsif taxable_income > current_limit
                            current_limit - previous_limit
        else
                            taxable_income - previous_limit
        end

        label = if current_limit == Float::INFINITY
                  "Above ₹#{previous_limit.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
        else
                  "₹#{previous_limit.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse} - ₹#{current_limit.to_i.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse}"
        end

        tax_for_slab = (taxable_in_slab * slab[:rate]).round(2)
        previous_limit = current_limit

        { slab: label, rate: "#{rate_percent}%", tax: tax_for_slab }
      end
    end

    def calculate_old_regime
      if @annual_gross <= 0.0
        return {
          regime: "OLD_REGIME",
          standard_deduction: 0.0,
          sec_80c: 0.0,
          sec_80d: 0.0,
          hra_exemption: 0.0,
          home_loan_interest: 0.0,
          nps_80ccd_1b: 0.0,
          total_deductions: 0.0,
          taxable_income: 0.0,
          tax_before_cess: 0.0,
          cess: 0.0,
          total_tax: 0.0,
          effective_tax_rate: 0.0,
          monthly_tds: 0.0,
          slabs_breakdown: []
        }
      end

      std_ded = [ OLD_REGIME_STD_DEDUCTION, @annual_gross ].min
      claimed_deductions = std_ded + @sec_80c + @sec_80d + @hra_exemption + @home_loan_interest + @nps_80ccd_1b
      total_deductions = [ claimed_deductions, @annual_gross ].min
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
        standard_deduction: std_ded,
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
