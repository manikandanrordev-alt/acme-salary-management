class Payslip < ApplicationRecord
  belongs_to :employee

  STATUSES = %w[generated dispatched cancelled].freeze

  validates :payroll_month, presence: true, format: { with: /\A\d{4}-\d{2}\z/, message: "must be in YYYY-MM format" }
  validates :employee_id, uniqueness: { scope: :payroll_month, message: "already has a payslip for this month" }
  validates :status, inclusion: { in: STATUSES }

  validates :gross_earnings, :total_deductions, :net_pay, numericality: { greater_than_or_equal_to: 0 }
  validates :basic_pay, :hra, :special_allowance, :diwali_bonus, numericality: { greater_than_or_equal_to: 0 }
  validates :epf_deduction, :pt_deduction, :tds_tax_deduction, :lop_deduction, numericality: { greater_than_or_equal_to: 0 }

  scope :for_month, ->(m) { where(payroll_month: m) if m.present? }
  scope :for_department, ->(dept_id) { joins(:employee).where(employees: { department_id: dept_id }) if dept_id.present? }
  scope :recent, -> { order(payroll_month: :desc, id: :desc) }

  def currency
    "INR"
  end

  def mark_as_emailed!(recipient = nil)
    update!(
      status: "dispatched",
      emailed_at: Time.current,
      email_recipient: recipient || employee.email
    )
  end

  # Convert net pay into Indian currency verbal format (e.g. ₹98,500 -> "Ninety-Eight Thousand Five Hundred Rupees Only")
  def net_pay_in_words
    amount_int = net_pay.to_i
    return "Zero Rupees Only" if amount_int.zero?

    units = ["", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten",
             "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"]
    tens = ["", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"]

    helper = lambda do |n|
      if n < 20
        units[n]
      elsif n < 100
        [tens[n / 10], units[n % 10]].reject(&:empty?).join(" ")
      elsif n < 1000
        [units[n / 100], "Hundred", helper.call(n % 100)].reject(&:empty?).join(" ")
      elsif n < 100_000 # Thousand
        [helper.call(n / 1000), "Thousand", helper.call(n % 1000)].reject(&:empty?).join(" ")
      elsif n < 10_000_000 # Lakh
        [helper.call(n / 100_000), "Lakh", helper.call(n % 100_000)].reject(&:empty?).join(" ")
      else # Crore
        [helper.call(n / 10_000_000), "Crore", helper.call(n % 10_000_000)].reject(&:empty?).join(" ")
      end
    end

    "#{helper.call(amount_int)} Rupees Only".squeeze(" ")
  end
end
