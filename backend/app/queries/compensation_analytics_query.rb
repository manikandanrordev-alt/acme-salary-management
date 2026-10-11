class CompensationAnalyticsQuery
  def self.call
    new.call
  end

  def call
    {
      currencies: currency_breakdown,
      departments: department_breakdown,
      countries: country_breakdown
    }
  end

  private

  # Aggregate metrics strictly grouped by currency for active salary records
  def currency_breakdown
    active_salaries = SalaryRecord.where(effective_to: nil)

    results = active_salaries
      .group(:currency)
      .select(
        "currency",
        "COUNT(*) AS headcount",
        "SUM(amount) AS total_payroll",
        "AVG(amount) AS average_salary",
        "MIN(amount) AS min_salary",
        "MAX(amount) AS max_salary"
      )
      .order(:currency)

    results.map do |row|
      {
        currency: row.currency,
        headcount: row.headcount.to_i,
        total_payroll: row.total_payroll.to_f.round(2),
        average_salary: row.average_salary.to_f.round(2),
        min_salary: row.min_salary.to_f.round(2),
        max_salary: row.max_salary.to_f.round(2)
      }
    end
  end

  # Breakdown by Department and Currency
  def department_breakdown
    results = SalaryRecord
      .where(effective_to: nil)
      .joins(employee: :department)
      .group("departments.id", "departments.name", "salary_records.currency")
      .select(
        "departments.id AS department_id",
        "departments.name AS department_name",
        "salary_records.currency AS currency",
        "COUNT(*) AS headcount",
        "SUM(salary_records.amount) AS total_payroll",
        "AVG(salary_records.amount) AS average_salary"
      )
      .order("departments.name ASC", "salary_records.currency ASC")

    results.map do |row|
      {
        department_id: row.department_id,
        department_name: row.department_name,
        currency: row.currency,
        headcount: row.headcount.to_i,
        total_payroll: row.total_payroll.to_f.round(2),
        average_salary: row.average_salary.to_f.round(2)
      }
    end
  end

  # Breakdown by Country and Currency
  def country_breakdown
    results = SalaryRecord
      .where(effective_to: nil)
      .joins(:employee)
      .group("employees.country_code", "salary_records.currency")
      .select(
        "employees.country_code AS country_code",
        "salary_records.currency AS currency",
        "COUNT(*) AS headcount",
        "SUM(salary_records.amount) AS total_payroll",
        "AVG(salary_records.amount) AS average_salary"
      )
      .order("employees.country_code ASC", "salary_records.currency ASC")

    results.map do |row|
      {
        country_code: row.country_code,
        currency: row.currency,
        headcount: row.headcount.to_i,
        total_payroll: row.total_payroll.to_f.round(2),
        average_salary: row.average_salary.to_f.round(2)
      }
    end
  end
end
