# frozen_string_literal: true

module Payroll
  class IndiaTaxCalculator
    # Statutory Reference:
    # Finance (No. 2) Act, 2024 / Central Board of Direct Taxes (CBDT)
    # Applicable Financial Year: FY 2024-25 & FY 2025-26 (Assessment Year 2025-26 & 2026-27)
    # Section 115BAC (New Tax Regime - Default Regime)
    FINANCIAL_YEAR = "FY 2024-25 / FY 2025-26"
    ASSESSMENT_YEAR = "AY 2025-26 / AY 2026-27"
    STANDARD_DEDUCTION = 75_000.0 # Increased from ₹50,000 to ₹75,000 under Finance (No. 2) Act, 2024
    REBATE_87A_LIMIT = 700_000.0 # Rebate under Section 87A applies if taxable income <= ₹7,00,000
    CESS_PERCENTAGE = 0.04 # 4% Health & Education Cess on income tax

    # Slabs for New Tax Regime under Section 115BAC:
    # 0 to 3,00,000: 0%
    # 3,00,001 to 7,00,000: 5% (₹20,000)
    # 7,00,001 to 10,00,000: 10% (₹30,000)
    # 10,00,001 to 12,00,000: 15% (₹30,000)
    # 12,00,001 to 15,00,000: 20% (₹60,000)
    # Above 15,00,000: 30%
    SLABS = [
      { limit: 300_000.0, rate: 0.00 },
      { limit: 700_000.0, rate: 0.05 },
      { limit: 1_000_000.0, rate: 0.10 },
      { limit: 1_200_000.0, rate: 0.15 },
      { limit: 1_500_000.0, rate: 0.20 },
      { limit: Float::INFINITY, rate: 0.30 }
    ].freeze

    def self.calculate(annual_gross_salary)
      new(annual_gross_salary).calculate
    end

    def initialize(annual_gross_salary)
      @annual_gross = [ annual_gross_salary.to_f, 0.0 ].max
    end

    def calculate
      taxable_income = [ @annual_gross - STANDARD_DEDUCTION, 0.0 ].max

      if taxable_income <= REBATE_87A_LIMIT
        return {
          financial_year: FINANCIAL_YEAR,
          assessment_year: ASSESSMENT_YEAR,
          annual_gross: @annual_gross.round(2),
          standard_deduction: STANDARD_DEDUCTION,
          taxable_income: taxable_income.round(2),
          base_tax: 0.0,
          rebate_87a: compute_slab_tax(taxable_income).round(2),
          marginal_relief: 0.0,
          cess: 0.0,
          total_annual_tax: 0.0,
          monthly_tds: 0.0
        }
      end

      # Calculate slab tax
      raw_base_tax = compute_slab_tax(taxable_income)
      base_tax = raw_base_tax
      marginal_relief = 0.0

      # Section 87A Marginal Relief proviso:
      # If taxable income marginally exceeds ₹7,00,000, tax payable cannot exceed
      # the amount by which taxable income exceeds ₹7,00,000.
      excess_over_limit = taxable_income - REBATE_87A_LIMIT
      if raw_base_tax > excess_over_limit
        marginal_relief = (raw_base_tax - excess_over_limit).round(2)
        base_tax = excess_over_limit
      end

      cess = (base_tax * CESS_PERCENTAGE).round(2)
      total_annual_tax = (base_tax + cess).round(2)
      monthly_tds = (total_annual_tax / 12.0).round(2)

      {
        financial_year: FINANCIAL_YEAR,
        assessment_year: ASSESSMENT_YEAR,
        annual_gross: @annual_gross.round(2),
        standard_deduction: STANDARD_DEDUCTION,
        taxable_income: taxable_income.round(2),
        base_tax: base_tax.round(2),
        rebate_87a: 0.0,
        marginal_relief: marginal_relief,
        cess: cess,
        total_annual_tax: total_annual_tax,
        monthly_tds: monthly_tds
      }
    end

    private

    def compute_slab_tax(taxable_income)
      tax = 0.0
      previous_limit = 0.0

      SLABS.each do |slab|
        break if taxable_income <= previous_limit

        current_slab_limit = slab[:limit]
        rate = slab[:rate]

        taxable_in_slab = if taxable_income > current_slab_limit
                            current_slab_limit - previous_limit
        else
                            taxable_income - previous_limit
        end

        tax += (taxable_in_slab * rate)
        previous_limit = current_slab_limit
      end

      tax
    end
  end
end
