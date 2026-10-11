# ACME Salary Management System - Deterministic Synthetic Seed Data
# Generates exactly 10,000 employees, 7 departments, admin/HR users, and realistic salary histories.

start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
puts "============================================================"
puts "  Seeding ACME Salary Management System (Target: 10,000 Emps)"
puts "============================================================"

# Seed fixed PRNG for 100% deterministic reproducibility
PRNG_SEED = 42
prng = Random.new(PRNG_SEED)

# 1. Clean slate
puts "-> Cleaning existing records..."
SalaryAuditLog.delete_all
SalaryRecord.delete_all
Employee.delete_all
Department.delete_all
User.delete_all

# 2. Seed Users
puts "-> Creating administrative and HR users..."
users_data = [
  {
    email: "hr_manager@acme.com",
    full_name: "Eleanor Vance (HR Director)",
    role: "hr_manager",
    encrypted_password: BCrypt::Password.create("Password123!"),
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    email: "admin@acme.com",
    full_name: "System Administrator",
    role: "admin",
    encrypted_password: BCrypt::Password.create("AdminSecret123!"),
    created_at: Time.current,
    updated_at: Time.current
  },
  {
    email: "auditor@acme.com",
    full_name: "Marcus Aurelius (Compliance Auditor)",
    role: "auditor",
    encrypted_password: BCrypt::Password.create("AuditorSecret123!"),
    created_at: Time.current,
    updated_at: Time.current
  }
]
User.insert_all!(users_data)
hr_user_id = User.find_by!(email: "hr_manager@acme.com").id

# 3. Seed Departments
puts "-> Creating departments..."
dept_definitions = [
  { name: "Engineering", code: "ENG" },
  { name: "Product Management", code: "PRD" },
  { name: "Sales & Business Dev", code: "SAL" },
  { name: "Marketing & Brand", code: "MKT" },
  { name: "Operations & Logistics", code: "OPS" },
  { name: "Finance & Legal", code: "FIN" },
  { name: "People & Human Resources", code: "HR" }
]
Department.insert_all!(dept_definitions.map { |d| d.merge(created_at: Time.current, updated_at: Time.current) })
dept_records = Department.order(:id).to_a
dept_ids = dept_records.map(&:id)

# 4. Reference Lists for Deterministic Employees
FIRST_NAMES = %w[
  James Mary John Patricia Robert Jennifer Michael Linda William Elizabeth
  David Barbara Richard Susan Joseph Jessica Thomas Sarah Charles Karen
  Christopher Nancy Daniel Lisa Matthew Betty Anthony Margaret Mark Sandra
  Donald Ashley Steven Kimberly Paul Emily Andrew Donna Joshua Michelle
  Arjun Priya Rajesh Deepa Vikram Ananya Rohan Meera Sanjay Sunita
  Klaus Hannah Lukas Sophie Felix Emma Maximilian Lea Jonas Mia
  Oliver Charlotte Harry Amelia George Isla Noah Ava Jack Sophia
  Wei Yan Jun Ling Ming Hua Hui Fang Jin Xiu
].freeze

LAST_NAMES = %w[
  Smith Johnson Williams Brown Jones Garcia Miller Davis Rodriguez Martinez
  Hernandez Lopez Gonzalez Wilson Anderson Thomas Taylor Moore Jackson Martin
  Lee Perez Thompson White Harris Sanchez Clark Ramirez Lewis Robinson
  Sharma Patel Gupta Singh Kumar Verma Reddy Rao Joshi Nair
  Mueller Schmidt Schneider Fischer Weber Meyer Wagner Becker Schulz Hoffmann
  Taylor Davies Evans Wilson Thomas Roberts Johnson Lewis Walker Robinson
  Tan Lim Ng Lee Goh Teo Wong Ong Koh Low
].freeze

COUNTRIES_CONFIG = [
  { code: "US", currency: "USD", min_salary: 65_000, max_salary: 185_000, weight: 35 },
  { code: "IN", currency: "INR", min_salary: 800_000, max_salary: 3_800_000, weight: 25 },
  { code: "DE", currency: "EUR", min_salary: 52_000, max_salary: 135_000, weight: 15 },
  { code: "GB", currency: "GBP", min_salary: 45_000, max_salary: 125_000, weight: 15 },
  { code: "SG", currency: "SGD", min_salary: 62_000, max_salary: 160_000, weight: 10 }
].freeze

# Weighted country picker
COUNTRY_PICKER = COUNTRIES_CONFIG.flat_map { |c| [ c ] * c[:weight] }.freeze

# Department weights (ENG: 30%, SAL: 20%, OPS: 15%, PRD: 10%, MKT: 10%, FIN: 8%, HR: 7%)
DEPT_WEIGHTS = [
  dept_records.find { |d| d.code == "ENG" }.id
] * 30 + [
  dept_records.find { |d| d.code == "SAL" }.id
] * 20 + [
  dept_records.find { |d| d.code == "OPS" }.id
] * 15 + [
  dept_records.find { |d| d.code == "PRD" }.id
] * 10 + [
  dept_records.find { |d| d.code == "MKT" }.id
] * 10 + [
  dept_records.find { |d| d.code == "FIN" }.id
] * 8 + [
  dept_records.find { |d| d.code == "HR" }.id
] * 7

TOTAL_EMPLOYEES = 10_000
BATCH_SIZE = 1_000

puts "-> Generating #{TOTAL_EMPLOYEES} synthetic employees in batches of #{BATCH_SIZE}..."

employee_rows = []
total_batches = (TOTAL_EMPLOYEES / BATCH_SIZE.to_f).ceil

today = Date.current
now = Time.current

(1..TOTAL_EMPLOYEES).each do |i|
  code = sprintf("ACME-%05d", i)
  first_name = FIRST_NAMES[prng.rand(FIRST_NAMES.size)]
  last_name = LAST_NAMES[prng.rand(LAST_NAMES.size)]
  email = "#{first_name.downcase}.#{last_name.downcase}.#{i}@acme-corp.internal"
  country_info = COUNTRY_PICKER[prng.rand(COUNTRY_PICKER.size)]
  dept_id = DEPT_WEIGHTS[prng.rand(DEPT_WEIGHTS.size)]

  # Tenure between 60 days and 5 years
  tenure_days = prng.rand(60..1825)
  hire_date = today - tenure_days.days

  status_roll = prng.rand(100)
  if status_roll < 90
    status = "active"
    term_date = nil
  elsif status_roll < 95
    status = "on_leave"
    term_date = nil
  else
    status = "terminated"
    term_date = hire_date + prng.rand(30..tenure_days).days
  end

  employee_rows << {
    id: i,
    employee_code: code,
    first_name: first_name,
    last_name: last_name,
    email: email,
    department_id: dept_id,
    country_code: country_info[:code],
    employment_status: status,
    hire_date: hire_date,
    termination_date: term_date,
    created_at: now,
    updated_at: now
  }
end

# Insert employees in batches
employee_rows.each_slice(BATCH_SIZE).with_index(1) do |batch, batch_num|
  Employee.insert_all!(batch)
  print "\r   Employees inserted: #{[ batch_num * BATCH_SIZE, TOTAL_EMPLOYEES ].min}/#{TOTAL_EMPLOYEES}"
end
puts ""

# 5. Generate Salary Records & Audit Logs
puts "-> Generating effective-dated salary records and audit trails..."

salary_rows = []
audit_rows = []
salary_record_id = 1
audit_log_id = 1

employee_rows.each do |emp|
  emp_id = emp[:id]
  country_info = COUNTRIES_CONFIG.find { |c| c[:code] == emp[:country_code] }
  currency = country_info[:currency]

  # Base starting salary rounded to nearest hundred
  base_salary = (prng.rand(country_info[:min_salary]..country_info[:max_salary]) / 100.0).round * 100.00
  hire_date = emp[:hire_date]
  tenure_years = ((today - hire_date) / 365.25).to_i

  # Decide number of historical revisions (0 to 3 based on tenure)
  num_revisions = if tenure_years >= 3 && prng.rand < 0.60
                    prng.rand(2..3)
  elsif tenure_years >= 1 && prng.rand < 0.45
                    1
  else
                    0
  end

  if num_revisions == 0
    # Single salary record active since hire date
    salary_rows << {
      id: salary_record_id,
      employee_id: emp_id,
      amount: base_salary,
      currency: currency,
      effective_from: hire_date,
      effective_to: nil,
      pay_frequency: "annual",
      change_reason: "initial_hire",
      created_at: now,
      updated_at: now
    }

    audit_rows << {
      id: audit_log_id,
      salary_record_id: salary_record_id,
      employee_id: emp_id,
      user_id: hr_user_id,
      action: "create",
      previous_amount: nil,
      new_amount: base_salary,
      previous_currency: nil,
      new_currency: currency,
      previous_effective_from: nil,
      new_effective_from: hire_date,
      previous_effective_to: nil,
      new_effective_to: nil,
      change_reason: "Initial compensation package on hire",
      ip_address: "127.0.0.1",
      user_agent: "ACME Seed Generator v1.0",
      created_at: hire_date.to_time
    }
    salary_record_id += 1
    audit_log_id += 1
  else
    # Historical multi-period revisions
    current_amount = base_salary
    period_start = hire_date
    revision_step_days = ((today - hire_date).to_i / (num_revisions + 1))

    (0..num_revisions).each do |rev_idx|
      is_last = (rev_idx == num_revisions)
      period_end = is_last ? nil : (period_start + revision_step_days.days - 1.day)
      reason = if rev_idx == 0
                 "initial_hire"
      elsif rev_idx.odd?
                 "annual_merit"
      else
                 "promotion"
      end

      salary_rows << {
        id: salary_record_id,
        employee_id: emp_id,
        amount: current_amount,
        currency: currency,
        effective_from: period_start,
        effective_to: period_end,
        pay_frequency: "annual",
        change_reason: reason,
        created_at: now,
        updated_at: now
      }

      audit_rows << {
        id: audit_log_id,
        salary_record_id: salary_record_id,
        employee_id: emp_id,
        user_id: hr_user_id,
        action: rev_idx == 0 ? "create" : "update",
        previous_amount: rev_idx == 0 ? nil : (current_amount / 1.08).round(2),
        new_amount: current_amount,
        previous_currency: rev_idx == 0 ? nil : currency,
        new_currency: currency,
        previous_effective_from: rev_idx == 0 ? nil : (period_start - revision_step_days.days),
        new_effective_from: period_start,
        previous_effective_to: rev_idx == 0 ? nil : (period_start - 1.day),
        new_effective_to: period_end,
        change_reason: "Revision #{rev_idx}: #{reason.humanize}",
        ip_address: "127.0.0.1",
        user_agent: "ACME Seed Generator v1.0",
        created_at: period_start.to_time
      }

      salary_record_id += 1
      audit_log_id += 1

      # Prepare next period
      period_start = period_end + 1.day if period_end
      current_amount = (current_amount * (1.0 + prng.rand(0.05..0.15))).round(2)
    end
  end
end

# Bulk insert salary records and audit logs
puts "-> Inserting #{salary_rows.size} salary records..."
salary_rows.each_slice(BATCH_SIZE) { |batch| SalaryRecord.insert_all!(batch) }

puts "-> Inserting #{audit_rows.size} salary audit logs..."
audit_rows.each_slice(BATCH_SIZE) { |batch| SalaryAuditLog.insert_all!(batch) }

elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time).round(2)

# 6. Verification and Summary
puts "\n============================================================"
puts "  Seeding Completed Successfully in #{elapsed}s!"
puts "============================================================"
puts "  Users:          #{User.count}"
puts "  Departments:    #{Department.count}"
puts "  Employees:      #{Employee.count} (Target: Exactly 10,000)"
puts "  Salary Records: #{SalaryRecord.count}"
puts "  Audit Logs:     #{SalaryAuditLog.count}"
puts "  Active Sal Recs:#{SalaryRecord.current.count}"
puts "============================================================"

raise "CRITICAL SEED ERROR: Expected 10,000 employees, found #{Employee.count}" unless Employee.count == 10_000
