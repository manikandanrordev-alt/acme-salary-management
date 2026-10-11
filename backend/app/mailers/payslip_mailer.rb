class PayslipMailer < ApplicationMailer
  default from: "payroll-disbursements@acme.com"

  def send_payslip(payslip_id)
    @payslip = Payslip.includes(:employee).find(payslip_id)
    @employee = @payslip.employee

    mail(
      to: @employee.email,
      subject: "ACME Enterprise - Monthly Salary Payslip for #{@payslip.payroll_month} (Net: ₹#{@payslip.net_pay})"
    )
  end
end
