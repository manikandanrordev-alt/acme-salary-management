# frozen_string_literal: true

namespace :acme do
  desc "Safely and idempotently seed the ACME production database with 10,000 employees"
  task seed_production: :environment do
    start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    puts "============================================================"
    puts "  ACME Production Data Seeder (Target: 10,000 Employees)"
    puts "============================================================"

    # Safety Opt-in Guard
    unless ENV["CONFIRM_PRODUCTION_SEED"] == "true"
      abort <<~MSG
        [ABORTED] Production seeding requires explicit opt-in confirmation.
        To execute against the targeted database, supply:
          CONFIRM_PRODUCTION_SEED=true bundle exec rails acme:seed_production
      MSG
    end

    PRNG_SEED = 42
    prng = Random.new(PRNG_SEED)

    # 1. Seed or Preserve Users (Non-destructive)
    puts "-> Checking administrative, HR manager, and auditor users..."
    users_data = [
      {
        email: "hr_manager@acme.com",
        full_name: "Eleanor Vance (HR Director)",
        role: "hr_manager",
        password: "Password123!"
      },
      {
        email: "hr_director@acme.com",
        full_name: "Eleanor Vance (HR Director)",
        role: "hr_manager",
        password: "Password123!"
      },
      {
        email: "admin@acme.com",
        full_name: "System Administrator",
        role: "admin",
        password: "Password123!"
      },
      {
        email: "auditor@acme.com",
        full_name: "Marcus Aurelius (Compliance Auditor)",
        role: "auditor",
        password: "Password123!"
      },
      {
        email: "compliance@acme.com",
        full_name: "Marcus Aurelius (Compliance Auditor)",
        role: "auditor",
        password: "Password123!"
      }
    ]

    users_data.each do |u|
      user = User.find_or_initialize_by(email: u[:email])
      if user.new_record?
        user.full_name = u[:full_name]
        user.role = u[:role]
        user.password = u[:password]
        user.password_confirmation = u[:password]
        user.save!
        puts "   Created user: #{u[:email]} (#{u[:role]})"
      else
        puts "   Preserved existing user: #{u[:email]}"
      end
    end

    hr_user_id = User.find_by!(email: "hr_manager@acme.com").id

    # 2. Seed Departments (Non-destructive)
    puts "-> Checking departments..."
    dept_definitions = [
      { name: "Engineering", code: "ENG" },
      { name: "Product Management", code: "PRD" },
      { name: "Sales & Business Dev", code: "SAL" },
      { name: "Marketing & Brand", code: "MKT" },
      { name: "Operations & Logistics", code: "OPS" },
      { name: "Finance & Legal", code: "FIN" },
      { name: "People & Human Resources", code: "HR" }
    ]

    dept_definitions.each do |d|
      Department.find_or_create_by!(code: d[:code]) do |dept|
        dept.name = d[:name]
      end
    end

    dept_records = Department.order(:id).to_a

    # Reference Lists for Deterministic Employees
    first_names = %w[
      James Mary John Patricia Robert Jennifer Michael Linda William Elizabeth
      David Barbara Richard Susan Joseph Jessica Thomas Sarah Charles Karen
      Christopher Nancy Daniel Lisa Matthew Betty Anthony Margaret Mark Sandra
      Donald Ashley Steven Kimberly Paul Emily Andrew Donna Joshua Michelle
      Arjun Priya Rajesh Deepa Vikram Ananya Rohan Meera Sanjay Sunita
      Klaus Hannah Lukas Sophie Felix Emma Maximilian Lea Jonas Mia
      Oliver Charlotte Harry Amelia George Isla Noah Ava Jack Sophia
      Wei Yan Jun Ling Ming Hua Hui Fang Jin Xiu
    ].freeze

    last_names = %w[
      Smith Johnson Williams Brown Jones Garcia Miller Davis Rodriguez Martinez
      Hernandez Lopez Gonzalez Wilson Anderson Thomas Taylor Moore Jackson Martin
      Lee Perez Thompson White Harris Sanchez Clark Ramirez Lewis Robinson
      Sharma Patel Gupta Singh Kumar Verma Reddy Rao Joshi Nair
      Mueller Schmidt Schneider Fischer Weber Meyer Wagner Becker Schulz Hoffmann
      Taylor Davies Evans Wilson Thomas Roberts Johnson Lewis Walker Robinson
      Tan Lim Ng Lee Goh Teo Wong Ong Koh Low
    ].freeze

    countries_config = [
      { code: "US", currency: "USD", min_salary: 65_000, max_salary: 185_000, weight: 35 },
      { code: "IN", currency: "INR", min_salary: 800_000, max_salary: 3_800_000, weight: 25 },
      { code: "DE", currency: "EUR", min_salary: 52_000, max_salary: 135_000, weight: 15 },
      { code: "GB", currency: "GBP", min_salary: 45_000, max_salary: 125_000, weight: 15 },
      { code: "SG", currency: "SGD", min_salary: 62_000, max_salary: 160_000, weight: 10 }
    ].freeze

    country_picker = countries_config.flat_map { |c| [ c ] * c[:weight] }.freeze

    dept_weights = [
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

    total_employees = 10_000
    batch_size = 1_000
    today = Date.current
    now = Time.current

    # 3. Seed Employees (Idempotent: Skip if already populated)
    if Employee.count >= total_employees
      puts "-> Employees already seeded (#{Employee.count} records found). Skipping employee generation."
    else
      puts "-> Generating #{total_employees} synthetic employees in batches of #{batch_size}..."
      employee_rows = []

      (1..total_employees).each do |i|
        code = sprintf("ACME-%05d", i)
        first_name = first_names[prng.rand(first_names.size)]
        last_name = last_names[prng.rand(last_names.size)]
        email = "#{first_name.downcase}.#{last_name.downcase}.#{i}@acme-corp.internal"
        country_info = country_picker[prng.rand(country_picker.size)]
        dept_id = dept_weights[prng.rand(dept_weights.size)]

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

      employee_rows.each_slice(batch_size).with_index(1) do |batch, batch_num|
        Employee.insert_all!(batch)
        print "\r   Employees inserted: #{[ batch_num * batch_size, total_employees ].min}/#{total_employees}"
      end
      puts ""

      # 4. Generate Salary Records & Audit Logs
      puts "-> Generating effective-dated salary records and audit trails..."
      salary_rows = []
      audit_rows = []
      salary_record_id = 1
      audit_log_id = 1

      employee_rows.each do |emp|
        emp_id = emp[:id]
        country_info = countries_config.find { |c| c[:code] == emp[:country_code] }
        currency = country_info[:currency]

        base_salary = (prng.rand(country_info[:min_salary]..country_info[:max_salary]) / 100.0).round * 100.00
        hire_date = emp[:hire_date]
        tenure_years = ((today - hire_date) / 365.25).to_i

        num_revisions = if tenure_years >= 3 && prng.rand < 0.60
                          prng.rand(2..3)
        elsif tenure_years >= 1 && prng.rand < 0.45
                          1
        else
                          0
        end

        if num_revisions == 0
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
            user_agent: "ACME Production Seeder v1.0",
            created_at: hire_date.to_time
          }
          salary_record_id += 1
          audit_log_id += 1
        else
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
              user_agent: "ACME Production Seeder v1.0",
              created_at: period_start.to_time
            }

            salary_record_id += 1
            audit_log_id += 1

            period_start = period_end + 1.day if period_end
            current_amount = (current_amount * (1.0 + prng.rand(0.05..0.15))).round(2)
          end
        end
      end

      puts "-> Inserting #{salary_rows.size} salary records..."
      salary_rows.each_slice(batch_size) { |batch| SalaryRecord.insert_all!(batch) }

      puts "-> Inserting #{audit_rows.size} salary audit logs..."
      audit_rows.each_slice(batch_size) { |batch| SalaryAuditLog.insert_all!(batch) }
    end

    # 5. Seed Initial Payslips (Starter cohort of 200 active employees)
    if Payslip.count.zero? && Employee.count.positive?
      puts "-> Generating starter batch of payslips for active cohort (200 employees)..."
      sample_month = Date.current.strftime("%Y-%m")
      active_sample = Employee.where(employment_status: "active").limit(200)
      payslip_count = 0

      active_sample.find_each do |emp|
        Payroll::PayslipGenerator.generate_for_employee(
          emp,
          payroll_month: sample_month,
          lop_days: (emp.id % 7 == 0) ? 1 : 0
        )
        payslip_count += 1
      end
      puts "-> Successfully generated #{payslip_count} initial payslips for #{sample_month}."
    else
      puts "-> Payslips already present (#{Payslip.count} found). Skipping payslip generation."
    end

    elapsed = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time).round(2)

    # 6. Final Summary
    puts "\n============================================================"
    puts "  Production Seeding Completed Successfully in #{elapsed}s!"
    puts "============================================================"
    puts "  Users:          #{User.count}"
    puts "  Departments:    #{Department.count}"
    puts "  Employees:      #{Employee.count} (Target: Exactly 10,000)"
    puts "  Salary Records: #{SalaryRecord.count}"
    puts "  Audit Logs:     #{SalaryAuditLog.count}"
    puts "  Active Sal Recs:#{SalaryRecord.current.count}"
    puts "  Payslips:       #{Payslip.count}"
    puts "============================================================"
  end
end
