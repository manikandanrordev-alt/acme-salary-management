require "csv"

class EmployeeCsvExportService
  HEADERS = [
    "employee_code",
    "first_name",
    "last_name",
    "email",
    "department",
    "country_code",
    "employment_status",
    "hire_date",
    "current_salary",
    "currency",
    "pay_frequency"
  ].freeze

  attr_reader :params

  def initialize(params = {})
    @params = params
  end

  def call
    scope = Employee.includes(:department, :salary_records)
    scope = apply_filters(scope)

    CSV.generate(headers: true) do |csv|
      csv << HEADERS

      scope.find_each(batch_size: 1000) do |emp|
        active_salary = emp.salary_records.find { |s| s.effective_to.nil? }

        csv << [
          emp.employee_code,
          emp.first_name,
          emp.last_name,
          emp.email,
          emp.department&.name,
          emp.country_code,
          emp.employment_status,
          emp.hire_date&.to_s,
          active_salary&.amount&.to_s,
          active_salary&.currency,
          active_salary&.pay_frequency
        ]
      end
    end
  end

  private

  def apply_filters(scope)
    if params[:search].present?
      q = "%#{params[:search].strip}%"
      scope = scope.where(
        "employees.employee_code LIKE :q OR employees.first_name LIKE :q OR employees.last_name LIKE :q OR employees.email LIKE :q",
        q: q
      )
    end

    scope = scope.where(department_id: params[:department_id]) if params[:department_id].present?
    scope = scope.where(country_code: params[:country_code].to_s.upcase) if params[:country_code].present?
    scope = scope.where(employment_status: params[:employment_status]) if params[:employment_status].present?
    scope.order("employees.id ASC")
  end
end
