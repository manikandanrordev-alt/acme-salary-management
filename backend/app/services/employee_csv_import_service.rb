require "csv"

class EmployeeCsvImportService
  attr_reader :csv_data, :current_user, :client_info

  def initialize(csv_data:, current_user:, client_info: {})
    @csv_data = csv_data
    @current_user = current_user
    @client_info = client_info
  end

  def call
    departments_by_name = Department.all.index_by { |d| d.name.downcase }
    departments_by_code = Department.all.index_by { |d| d.code.downcase }

    created_count = 0
    errors = []
    row_number = 1 # 1 is header

    CSV.parse(csv_data, headers: true, header_converters: :downcase) do |row|
      row_number += 1
      row_errors = []

      code = row["employee_code"]&.strip
      first_name = row["first_name"]&.strip
      last_name = row["last_name"]&.strip
      email = row["email"]&.strip&.downcase
      dept_val = row["department"]&.strip
      country_code = row["country_code"]&.strip&.upcase
      status = row["employment_status"]&.strip&.downcase || "active"
      hire_date_str = row["hire_date"]&.strip
      salary_str = row["current_salary"]&.strip || row["salary"]&.strip
      currency = row["currency"]&.strip&.upcase || "USD"
      frequency = row["pay_frequency"]&.strip&.downcase || "annual"

      row_errors << "Employee code is required" if code.blank?
      row_errors << "First name is required" if first_name.blank?
      row_errors << "Last name is required" if last_name.blank?
      row_errors << "Email is required" if email.blank?
      row_errors << "Country code is required" if country_code.blank?
      row_errors << "Country code must be US, GB, DE, IN, or SG" unless %w[US GB DE IN SG].include?(country_code)

      dept = departments_by_name[dept_val&.downcase] || departments_by_code[dept_val&.downcase]
      row_errors << "Department '#{dept_val}' does not exist" if dept.nil? && dept_val.present?
      row_errors << "Department is required" if dept_val.blank?

      hire_date = parse_date(hire_date_str)
      row_errors << "Valid hire date (YYYY-MM-DD) is required" if hire_date.nil?

      salary_amount = parse_decimal(salary_str)
      if salary_amount.nil? || salary_amount <= 0
        row_errors << "Current salary must be a positive number"
      end

      if Employee.exists?(employee_code: code)
        row_errors << "Employee code '#{code}' is already taken"
      end

      if Employee.exists?(email: email)
        row_errors << "Email '#{email}' is already taken"
      end

      if row_errors.any?
        errors << { row: row_number, code: code || "UNKNOWN", errors: row_errors }
        next
      end

      # Create employee and initial salary atomically
      ActiveRecord::Base.transaction do
        employee = Employee.create!(
          employee_code: code,
          first_name: first_name,
          last_name: last_name,
          email: email,
          department: dept,
          country_code: country_code,
          employment_status: status,
          hire_date: hire_date
        )

        salary_record = employee.salary_records.create!(
          amount: salary_amount,
          currency: currency,
          effective_from: hire_date,
          effective_to: nil,
          pay_frequency: frequency,
          change_reason: "initial_placement"
        )

        SalaryAuditLog.create!(
          salary_record: salary_record,
          employee: employee,
          user: current_user,
          action: "create",
          new_amount: salary_amount,
          new_currency: currency,
          new_effective_from: hire_date,
          change_reason: "csv_bulk_import",
          ip_address: client_info[:ip_address],
          user_agent: client_info[:user_agent]
        )

        created_count += 1
      end
    rescue ActiveRecord::RecordInvalid => e
      errors << { row: row_number, code: code, errors: e.record.errors.full_messages }
    end

    {
      total_rows: row_number - 1,
      created_count: created_count,
      errors: errors,
      success: errors.empty?
    }
  rescue CSV::MalformedCSVError => e
    {
      total_rows: 0,
      created_count: 0,
      errors: [ { row: 0, code: "FILE_ERROR", errors: [ "Malformed CSV: #{e.message}" ] } ],
      success: false
    }
  end

  private

  def parse_date(str)
    return nil if str.blank?
    Date.parse(str)
  rescue ArgumentError, TypeError
    nil
  end

  def parse_decimal(str)
    return nil if str.blank?
    BigDecimal(str)
  rescue ArgumentError, TypeError
    nil
  end
end
