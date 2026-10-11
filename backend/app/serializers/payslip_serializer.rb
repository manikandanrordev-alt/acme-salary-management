# frozen_string_literal: true

class PayslipSerializer
  def self.render(payslip)
    {
      id: payslip.id,
      employee_id: payslip.employee_id,
      employee: {
        id: payslip.employee.id,
        employee_code: payslip.employee.employee_code,
        full_name: payslip.employee.full_name,
        email: payslip.employee.email,
        job_title: payslip.employee.current_salary_record&.change_reason || "Employee",
        department: {
          id: payslip.employee.department&.id,
          name: payslip.employee.department&.name,
          code: payslip.employee.department&.code
        }
      },
      payroll_month: payslip.payroll_month,
      financial_year: payslip.financial_year,
      currency: "INR",
      currency_symbol: "₹",
      # Earnings
      basic_pay: payslip.basic_pay.to_f,
      hra: payslip.hra.to_f,
      special_allowance: payslip.special_allowance.to_f,
      diwali_bonus: payslip.diwali_bonus.to_f,
      gross_earnings: payslip.gross_earnings.to_f,
      # Deductions
      epf_deduction: payslip.epf_deduction.to_f,
      pt_deduction: payslip.pt_deduction.to_f,
      tds_tax_deduction: payslip.tds_tax_deduction.to_f,
      lop_deduction: payslip.lop_deduction.to_f,
      total_deductions: payslip.total_deductions.to_f,
      # Net Take-Home
      net_pay: payslip.net_pay.to_f,
      net_pay_in_words: payslip.net_pay_in_words,
      # Attendance
      working_days: payslip.working_days,
      paid_leaves: payslip.paid_leaves,
      lop_days: payslip.lop_days,
      # Dispatch info
      status: payslip.status,
      email_recipient: payslip.email_recipient,
      emailed_at: payslip.emailed_at&.iso8601,
      created_at: payslip.created_at.iso8601
    }
  end

  def self.render_collection(payslips)
    payslips.map { |p| render(p) }
  end
end
