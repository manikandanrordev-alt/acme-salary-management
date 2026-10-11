class CreatePayslips < ActiveRecord::Migration[8.1]
  def change
    create_table :payslips do |t|
      t.references :employee, null: false, foreign_key: { on_delete: :cascade }
      t.string :payroll_month, null: false, limit: 7 # e.g. "2026-10"
      t.string :financial_year, null: false, default: "2024-2025"

      # Earnings (in INR ₹)
      t.decimal :basic_pay, precision: 12, scale: 2, null: false, default: 0
      t.decimal :hra, precision: 12, scale: 2, null: false, default: 0
      t.decimal :special_allowance, precision: 12, scale: 2, null: false, default: 0
      t.decimal :diwali_bonus, precision: 12, scale: 2, null: false, default: 0
      t.decimal :gross_earnings, precision: 12, scale: 2, null: false, default: 0

      # Statutory & Tax Deductions (in INR ₹)
      t.decimal :epf_deduction, precision: 12, scale: 2, null: false, default: 0
      t.decimal :pt_deduction, precision: 12, scale: 2, null: false, default: 0
      t.decimal :tds_tax_deduction, precision: 12, scale: 2, null: false, default: 0
      t.decimal :lop_deduction, precision: 12, scale: 2, null: false, default: 0
      t.decimal :total_deductions, precision: 12, scale: 2, null: false, default: 0

      # Net Disbursed Pay (in INR ₹)
      t.decimal :net_pay, precision: 12, scale: 2, null: false, default: 0

      # Attendance & Leave Metrics
      t.integer :working_days, default: 30, null: false
      t.integer :paid_leaves, default: 0, null: false
      t.integer :lop_days, default: 0, null: false

      # Dispatch and Status
      t.string :status, default: "generated", null: false
      t.string :email_recipient
      t.datetime :emailed_at

      t.timestamps
    end

    add_index :payslips, [:employee_id, :payroll_month], unique: true, name: "idx_payslips_emp_month"
    add_index :payslips, :payroll_month
    add_index :payslips, :status
  end
end
