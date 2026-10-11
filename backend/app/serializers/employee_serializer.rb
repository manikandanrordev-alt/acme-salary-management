class EmployeeSerializer
  def self.render_collection(employees)
    employees.map { |emp| render_summary(emp) }
  end

  def self.render_summary(employee)
    current_salary = employee.current_salary_record

    {
      id: employee.id,
      employee_code: employee.employee_code,
      first_name: employee.first_name,
      last_name: employee.last_name,
      full_name: employee.full_name,
      email: employee.email,
      country_code: employee.country_code,
      employment_status: employee.employment_status,
      hire_date: employee.hire_date,
      termination_date: employee.termination_date,
      department: {
        id: employee.department_id,
        name: employee.department&.name,
        code: employee.department&.code
      },
      current_salary: current_salary ? render_salary(current_salary) : nil
    }
  end

  def self.render_detail(employee)
    summary = render_summary(employee)
    summary.merge(
      salary_history: employee.salary_records.reorder(effective_from: :desc).map { |sr| render_salary(sr) },
      created_at: employee.created_at,
      updated_at: employee.updated_at
    )
  end

  def self.render_salary(salary_record)
    {
      id: salary_record.id,
      amount: salary_record.amount.to_s,
      currency: salary_record.currency,
      pay_frequency: salary_record.pay_frequency,
      effective_from: salary_record.effective_from,
      effective_to: salary_record.effective_to,
      change_reason: salary_record.change_reason,
      created_at: salary_record.created_at
    }
  end
end
