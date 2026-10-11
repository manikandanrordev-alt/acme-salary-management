# frozen_string_literal: true

module Payroll
  class SalaryStructureService
    PROFESSIONAL_TAX = 200.0 # Standard Indian state PT ₹200/month
    BASIC_PERCENTAGE = 0.50 # 50% of Gross as Basic
    HRA_PERCENTAGE_OF_BASIC = 0.40 # 40% of Basic as HRA
    EPF_RATE = 0.12 # 12% statutory employee EPF

    def self.decompose(annual_ctc, working_days: 30, lop_days: 0, festive_bonus: 0.0)
      new(annual_ctc, working_days: working_days, lop_days: lop_days, festive_bonus: festive_bonus).decompose
    end

    def initialize(annual_ctc, working_days: 30, lop_days: 0, festive_bonus: 0.0)
      @annual_ctc = [ annual_ctc.to_f, 0.0 ].max
      @working_days = [ working_days.to_i, 1 ].max
      @lop_days = [ lop_days.to_i, 0 ].max
      @festive_bonus = [ festive_bonus.to_f, 0.0 ].max
    end

    def decompose
      monthly_gross = (@annual_ctc / 12.0).round(2)

      basic_pay = (monthly_gross * BASIC_PERCENTAGE).round(2)
      hra = (basic_pay * HRA_PERCENTAGE_OF_BASIC).round(2)
      special_allowance = [ monthly_gross - (basic_pay + hra), 0.0 ].max.round(2)

      gross_earnings = (monthly_gross + @festive_bonus).round(2)

      # Deductions
      epf_deduction = (basic_pay * EPF_RATE).round(2)
      pt_deduction = monthly_gross > 15_000 ? PROFESSIONAL_TAX : 0.0

      # Income Tax TDS
      tax_info = IndiaTaxCalculator.calculate(@annual_ctc)
      tds_tax_deduction = tax_info[:monthly_tds]

      # Leave Loss of Pay (LOP) calculation
      lop_deduction = ((monthly_gross / @working_days.to_f) * @lop_days).round(2)

      total_deductions = (epf_deduction + pt_deduction + tds_tax_deduction + lop_deduction).round(2)
      net_pay = [ gross_earnings - total_deductions, 0.0 ].max.round(2)

      {
        annual_ctc: @annual_ctc.round(2),
        monthly_gross: monthly_gross,
        basic_pay: basic_pay,
        hra: hra,
        special_allowance: special_allowance,
        diwali_bonus: @festive_bonus.round(2),
        gross_earnings: gross_earnings,
        epf_deduction: epf_deduction,
        pt_deduction: pt_deduction,
        tds_tax_deduction: tds_tax_deduction,
        lop_deduction: lop_deduction,
        total_deductions: total_deductions,
        net_pay: net_pay,
        tax_info: tax_info,
        working_days: @working_days,
        paid_leaves: [ @working_days - @lop_days, 0 ].max,
        lop_days: @lop_days
      }
    end
  end
end
