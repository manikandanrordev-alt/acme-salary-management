# frozen_string_literal: true

module Payroll
  class PayslipGenerator
    USD_TO_INR_RATE = 85.0

    def self.generate_for_employee(employee, payroll_month:, lop_days: 0, include_diwali_bonus: false, bonus_percentage: 8.33)
      new(employee, payroll_month: payroll_month, lop_days: lop_days, include_diwali_bonus: include_diwali_bonus, bonus_percentage: bonus_percentage).generate
    end

    def initialize(employee, payroll_month:, lop_days: 0, include_diwali_bonus: false, bonus_percentage: 8.33)
      @employee = employee
      @payroll_month = payroll_month
      @lop_days = lop_days.to_i
      @include_diwali_bonus = include_diwali_bonus
      @bonus_percentage = bonus_percentage.to_f
    end

    def generate
      active_record = @employee.current_salary_record
      raise StandardError, "Employee #{@employee.employee_code} has no active compensation record" unless active_record

      # Determine Annual CTC in INR (₹)
      raw_amount = active_record.amount.to_f
      annual_inr_ctc = if active_record.currency == "INR" || raw_amount >= 300_000
                         raw_amount
      else
                         (raw_amount * USD_TO_INR_RATE).round(2)
      end

      # Determine if Diwali bonus applies (either requested or month is October "YYYY-10" / November "YYYY-11")
      month_num = @payroll_month.split("-").last.to_i
      festive_month = @include_diwali_bonus || [ 10, 11 ].include?(month_num)

      bonus_result = DiwaliBonusService.calculate_bonus(
        annual_inr_ctc,
        bonus_percentage: @bonus_percentage > 0 ? @bonus_percentage : 8.33,
        is_festive_month: festive_month
      )

      decomposed = SalaryStructureService.decompose(
        annual_inr_ctc,
        working_days: 30,
        lop_days: @lop_days,
        festive_bonus: bonus_result[:bonus_amount]
      )

      # Create or update payslip record for the month
      payslip = Payslip.find_or_initialize_by(
        employee_id: @employee.id,
        payroll_month: @payroll_month
      )

      payslip.assign_attributes(
        financial_year: compute_financial_year(@payroll_month),
        basic_pay: decomposed[:basic_pay],
        hra: decomposed[:hra],
        special_allowance: decomposed[:special_allowance],
        diwali_bonus: decomposed[:diwali_bonus],
        gross_earnings: decomposed[:gross_earnings],
        epf_deduction: decomposed[:epf_deduction],
        pt_deduction: decomposed[:pt_deduction],
        tds_tax_deduction: decomposed[:tds_tax_deduction],
        lop_deduction: decomposed[:lop_deduction],
        total_deductions: decomposed[:total_deductions],
        net_pay: decomposed[:net_pay],
        working_days: decomposed[:working_days],
        paid_leaves: decomposed[:paid_leaves],
        lop_days: decomposed[:lop_days],
        status: payslip.status.presence || "generated"
      )

      payslip.save!
      payslip
    end

    private

    def compute_financial_year(month_str)
      parts = month_str.split("-")
      year = parts.first.to_i
      month = parts.last.to_i

      if month >= 4
        "#{year}-#{year + 1}"
      else
        "#{year - 1}-#{year}"
      end
    end
  end
end
