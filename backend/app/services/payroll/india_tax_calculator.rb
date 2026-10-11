# frozen_string_literal: true

module Payroll
  class IndiaTaxCalculator
    # Statutory Reference:
    # Central Board of Direct Taxes (CBDT) / Ministry of Finance, Government of India
    # Section 115BAC (New Tax Regime - Default Regime)
    #
    # Supported Financial Years and Legislative Authorities:
    # - FY 2023-24 (AY 2024-25): Finance Act, 2023 (Std Ded ₹50k, 6 slabs, 87A rebate up to ₹7L)
    # - FY 2024-25 (AY 2025-26): Finance (No. 2) Act, 2024 (Std Ded ₹75k, 6 restructured slabs, 87A rebate up to ₹7L + marginal relief)
    # - FY 2025-26 (AY 2026-27): Statutory rates continued under Finance Act
    # - FY 2026-27 (AY 2027-28): Current Ongoing Financial Year (October 2026 operational year)

    YEAR_RULES = {
      "FY 2023-24" => {
        assessment_year: "AY 2024-25",
        standard_deduction: 50_000.0,
        rebate_87a_limit: 700_000.0,
        slabs: [
          { limit: 300_000.0, rate: 0.00 },
          { limit: 600_000.0, rate: 0.05 },
          { limit: 900_000.0, rate: 0.10 },
          { limit: 1_200_000.0, rate: 0.15 },
          { limit: 1_500_000.0, rate: 0.20 },
          { limit: Float::INFINITY, rate: 0.30 }
        ].freeze
      }.freeze,
      "FY 2024-25" => {
        assessment_year: "AY 2025-26",
        standard_deduction: 75_000.0,
        rebate_87a_limit: 700_000.0,
        slabs: [
          { limit: 300_000.0, rate: 0.00 },
          { limit: 700_000.0, rate: 0.05 },
          { limit: 1_000_000.0, rate: 0.10 },
          { limit: 1_200_000.0, rate: 0.15 },
          { limit: 1_500_000.0, rate: 0.20 },
          { limit: Float::INFINITY, rate: 0.30 }
        ].freeze
      }.freeze,
      "FY 2025-26" => {
        assessment_year: "AY 2026-27",
        standard_deduction: 75_000.0,
        rebate_87a_limit: 700_000.0,
        slabs: [
          { limit: 300_000.0, rate: 0.00 },
          { limit: 700_000.0, rate: 0.05 },
          { limit: 1_000_000.0, rate: 0.10 },
          { limit: 1_200_000.0, rate: 0.15 },
          { limit: 1_500_000.0, rate: 0.20 },
          { limit: Float::INFINITY, rate: 0.30 }
        ].freeze
      }.freeze,
      "FY 2026-27" => {
        assessment_year: "AY 2027-28",
        standard_deduction: 75_000.0,
        rebate_87a_limit: 700_000.0,
        slabs: [
          { limit: 300_000.0, rate: 0.00 },
          { limit: 700_000.0, rate: 0.05 },
          { limit: 1_000_000.0, rate: 0.10 },
          { limit: 1_200_000.0, rate: 0.15 },
          { limit: 1_500_000.0, rate: 0.20 },
          { limit: Float::INFINITY, rate: 0.30 }
        ].freeze
      }.freeze
    }.freeze

    SUPPORTED_FINANCIAL_YEARS = YEAR_RULES.keys.freeze
    FINANCIAL_YEAR = "FY 2026-27"
    ASSESSMENT_YEAR = "AY 2027-28"
    CESS_PERCENTAGE = 0.04 # 4% Health & Education Cess on income tax

    def self.current_financial_year(date = Date.current)
      if date.month >= 4
        "FY #{date.year}-#{(date.year + 1).to_s[-2..]}"
      else
        "FY #{date.year - 1}-#{date.year.to_s[-2..]}"
      end
    end

    def self.current_assessment_year(date = Date.current)
      start_year = date.month >= 4 ? date.year + 1 : date.year
      "AY #{start_year}-#{(start_year + 1).to_s[-2..]}"
    end

    def self.calculate(annual_gross_salary, date: Date.current, financial_year: nil)
      new(annual_gross_salary, date: date, financial_year: financial_year).calculate
    end

    attr_reader :financial_year, :assessment_year, :standard_deduction, :rebate_87a_limit, :slabs

    def initialize(annual_gross_salary, date: Date.current, financial_year: nil)
      @date = date || Date.current
      @financial_year = financial_year || self.class.current_financial_year(@date)
      @year_config = YEAR_RULES[@financial_year] || YEAR_RULES[FINANCIAL_YEAR]

      @assessment_year = @year_config[:assessment_year]
      @standard_deduction = @year_config[:standard_deduction]
      @rebate_87a_limit = @year_config[:rebate_87a_limit]
      @slabs = @year_config[:slabs]

      # Zero or negative gross salary handling: clamp to 0.0
      @annual_gross = [ annual_gross_salary.to_f, 0.0 ].max
    end

    def calculate
      # Zero or negative salary boundary handling:
      if @annual_gross <= 0.0
        return {
          financial_year: @financial_year,
          assessment_year: @assessment_year,
          supported_financial_years: SUPPORTED_FINANCIAL_YEARS,
          annual_gross: 0.0,
          standard_deduction: 0.0,
          taxable_income: 0.0,
          base_tax: 0.0,
          rebate_87a: 0.0,
          marginal_relief: 0.0,
          cess: 0.0,
          total_annual_tax: 0.0,
          monthly_tds: 0.0
        }
      end

      # Standard deduction utilized cannot exceed annual gross salary
      std_ded_utilized = [ @standard_deduction, @annual_gross ].min
      taxable_income = [ @annual_gross - std_ded_utilized, 0.0 ].max

      # Section 87A Rebate check (Full rebate if taxable income <= rebate_87a_limit)
      if taxable_income <= @rebate_87a_limit
        raw_tax = compute_slab_tax(taxable_income)
        return {
          financial_year: @financial_year,
          assessment_year: @assessment_year,
          supported_financial_years: SUPPORTED_FINANCIAL_YEARS,
          annual_gross: @annual_gross.round(2),
          standard_deduction: std_ded_utilized.round(2),
          taxable_income: taxable_income.round(2),
          base_tax: 0.0,
          rebate_87a: raw_tax.round(2),
          marginal_relief: 0.0,
          cess: 0.0,
          total_annual_tax: 0.0,
          monthly_tds: 0.0
        }
      end

      # Calculate raw slab tax
      raw_base_tax = compute_slab_tax(taxable_income)
      base_tax = raw_base_tax
      marginal_relief = 0.0

      # Section 87A Marginal Relief proviso:
      # If taxable income marginally exceeds rebate limit, tax payable cannot exceed
      # the amount by which taxable income exceeds the rebate limit.
      excess_over_limit = taxable_income - @rebate_87a_limit
      if raw_base_tax > excess_over_limit
        marginal_relief = (raw_base_tax - excess_over_limit).round(2)
        base_tax = excess_over_limit
      end

      cess = (base_tax * CESS_PERCENTAGE).round(2)
      total_annual_tax = (base_tax + cess).round(2)
      monthly_tds = (total_annual_tax / 12.0).round(2)

      {
        financial_year: @financial_year,
        assessment_year: @assessment_year,
        supported_financial_years: SUPPORTED_FINANCIAL_YEARS,
        annual_gross: @annual_gross.round(2),
        standard_deduction: std_ded_utilized.round(2),
        taxable_income: taxable_income.round(2),
        base_tax: base_tax.round(2),
        rebate_87a: 0.0,
        marginal_relief: marginal_relief,
        cess: cess,
        total_annual_tax: total_annual_tax,
        monthly_tds: monthly_tds
      }
    end

    def compute_slab_tax(taxable_income)
      tax = 0.0
      previous_limit = 0.0

      @slabs.each do |slab|
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
