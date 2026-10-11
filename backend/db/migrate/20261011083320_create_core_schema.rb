class CreateCoreSchema < ActiveRecord::Migration[8.1]
  def change
    # Users (HR Managers, Admins, Auditors)
    create_table :users do |t|
      t.string :email, null: false
      t.string :encrypted_password, null: false
      t.string :role, null: false, default: "hr_manager"
      t.string :full_name, null: false

      t.timestamps
    end
    add_index :users, :email, unique: true

    # Departments
    create_table :departments do |t|
      t.string :name, null: false
      t.string :code, null: false

      t.timestamps
    end
    add_index :departments, :name, unique: true
    add_index :departments, :code, unique: true

    # Employees
    create_table :employees do |t|
      t.string :employee_code, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.references :department, null: false, foreign_key: { on_delete: :restrict }
      t.string :country_code, limit: 3, null: false
      t.string :employment_status, null: false, default: "active"
      t.date :hire_date, null: false
      t.date :termination_date

      t.timestamps
    end
    add_index :employees, :employee_code, unique: true
    add_index :employees, :email, unique: true
    add_index :employees, [:department_id, :employment_status], name: "idx_emp_dept_status"
    add_index :employees, [:country_code, :employment_status], name: "idx_emp_country_status"
    add_index :employees, [:last_name, :first_name], name: "idx_emp_name_search"

    # Salary Records (Effective-dated)
    create_table :salary_records do |t|
      t.references :employee, null: false, foreign_key: { on_delete: :cascade }
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :currency, limit: 3, null: false
      t.date :effective_from, null: false
      t.date :effective_to
      t.string :pay_frequency, null: false, default: "annual"
      t.string :change_reason, null: false

      t.timestamps
    end
    add_index :salary_records, [:employee_id, :effective_from, :effective_to], name: "idx_salary_emp_dates"
    add_index :salary_records, [:currency, :amount], name: "idx_salary_curr_amount"

    # Salary Audit Logs (Immutable audit trail)
    create_table :salary_audit_logs do |t|
      t.references :salary_record, foreign_key: { on_delete: :nullify }
      t.references :employee, null: false, foreign_key: { on_delete: :restrict }
      t.references :user, null: false, foreign_key: { on_delete: :restrict }
      t.string :action, null: false
      t.decimal :previous_amount, precision: 12, scale: 2
      t.decimal :new_amount, precision: 12, scale: 2, null: false
      t.string :previous_currency, limit: 3
      t.string :new_currency, limit: 3, null: false
      t.date :previous_effective_from
      t.date :new_effective_from, null: false
      t.date :previous_effective_to
      t.date :new_effective_to
      t.string :change_reason, null: false
      t.string :ip_address, limit: 45
      t.string :user_agent
      t.datetime :created_at, precision: 6, null: false
    end
    add_index :salary_audit_logs, [:employee_id, :created_at], name: "idx_audit_emp_created"
    add_index :salary_audit_logs, [:user_id, :created_at], name: "idx_audit_user_created"
  end
end
