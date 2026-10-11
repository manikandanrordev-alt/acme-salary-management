# frozen_string_literal: true

module Payroll
  class IndiaTaxCalculator
    STANDARD_DEDUCTION = 75_000.0 # FY 2024-25 / 2025-26 New Regime Standard Deduction
    REBATE_87A_LIMIT = 700_000.0 # Full rebate under 87A if taxable income <= 7L
    CESS_PERCENTAGE = 0.04 # 4% Health & Education Cess

    # Slabs for New Tax Regime
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
          annual_gross: @annual_gross.round(2),
          standard_deduction: STANDARD_DEDUCTION,
          taxable_income: taxable_income.round(2),
          base_tax: 0.0,
          rebate_87a: 0.0,
          cess: 0.0,
          total_annual_tax: 0.0,
          monthly_tds: 0.0
        }
      end

      # Calculate slab tax
      base_tax = compute_slab_tax(taxable_income)
      cess = (base_tax * CESS_PERCENTAGE).round(2)
      total_annual_tax = (base_tax + cess).round(2)
      monthly_tds = (total_annual_tax / 12.0).round(2)

      {
        annual_gross: @annual_gross.round(2),
        standard_deduction: STANDARD_DEDUCTION,
        taxable_income: taxable_income.round(2),
        base_tax: base_tax.round(2),
        rebate_87a: 0.0,
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
