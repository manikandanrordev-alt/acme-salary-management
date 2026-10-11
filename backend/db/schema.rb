# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_10_11_115254) do
  create_table "departments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_departments_on_code", unique: true
    t.index ["name"], name: "index_departments_on_name", unique: true
  end

  create_table "employees", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "employee_code", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.bigint "department_id", null: false
    t.string "country_code", limit: 3, null: false
    t.string "employment_status", default: "active", null: false
    t.date "hire_date", null: false
    t.date "termination_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_code", "employment_status"], name: "idx_emp_country_status"
    t.index ["department_id", "employment_status"], name: "idx_emp_dept_status"
    t.index ["department_id"], name: "index_employees_on_department_id"
    t.index ["email"], name: "index_employees_on_email", unique: true
    t.index ["employee_code"], name: "index_employees_on_employee_code", unique: true
    t.index ["last_name", "first_name"], name: "idx_emp_name_search"
  end

  create_table "payslips", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.string "payroll_month", limit: 7, null: false
    t.string "financial_year", default: "2024-2025", null: false
    t.decimal "basic_pay", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "hra", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "special_allowance", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "diwali_bonus", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "gross_earnings", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "epf_deduction", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "pt_deduction", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "tds_tax_deduction", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "lop_deduction", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "total_deductions", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "net_pay", precision: 12, scale: 2, default: "0.0", null: false
    t.integer "working_days", default: 30, null: false
    t.integer "paid_leaves", default: 0, null: false
    t.integer "lop_days", default: 0, null: false
    t.string "status", default: "generated", null: false
    t.string "email_recipient"
    t.datetime "emailed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "payroll_month"], name: "idx_payslips_emp_month", unique: true
    t.index ["employee_id"], name: "index_payslips_on_employee_id"
    t.index ["payroll_month"], name: "index_payslips_on_payroll_month"
    t.index ["status"], name: "index_payslips_on_status"
  end

  create_table "salary_audit_logs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "salary_record_id"
    t.bigint "employee_id", null: false
    t.bigint "user_id", null: false
    t.string "action", null: false
    t.decimal "previous_amount", precision: 12, scale: 2
    t.decimal "new_amount", precision: 12, scale: 2, null: false
    t.string "previous_currency", limit: 3
    t.string "new_currency", limit: 3, null: false
    t.date "previous_effective_from"
    t.date "new_effective_from", null: false
    t.date "previous_effective_to"
    t.date "new_effective_to"
    t.string "change_reason", null: false
    t.string "ip_address", limit: 45
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.index ["employee_id", "created_at"], name: "idx_audit_emp_created"
    t.index ["employee_id"], name: "index_salary_audit_logs_on_employee_id"
    t.index ["salary_record_id"], name: "index_salary_audit_logs_on_salary_record_id"
    t.index ["user_id", "created_at"], name: "idx_audit_user_created"
    t.index ["user_id"], name: "index_salary_audit_logs_on_user_id"
  end

  create_table "salary_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.string "currency", limit: 3, null: false
    t.date "effective_from", null: false
    t.date "effective_to"
    t.string "pay_frequency", default: "annual", null: false
    t.string "change_reason", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency", "amount"], name: "idx_salary_curr_amount"
    t.index ["effective_to", "currency", "amount"], name: "idx_sal_active_currency_amount"
    t.index ["effective_to"], name: "idx_sal_effective_to"
    t.index ["employee_id", "effective_from", "effective_to"], name: "idx_salary_emp_dates"
    t.index ["employee_id"], name: "index_salary_records_on_employee_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email", null: false
    t.string "encrypted_password", null: false
    t.string "role", default: "hr_manager", null: false
    t.string "full_name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "employees", "departments"
  add_foreign_key "payslips", "employees", on_delete: :cascade
  add_foreign_key "salary_audit_logs", "employees"
  add_foreign_key "salary_audit_logs", "salary_records", on_delete: :nullify
  add_foreign_key "salary_audit_logs", "users"
  add_foreign_key "salary_records", "employees", on_delete: :cascade
end
