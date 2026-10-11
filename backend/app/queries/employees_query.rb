class EmployeesQuery
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  attr_reader :params, :relation

  def initialize(params = {}, relation = Employee.all)
    @params = params
    @relation = relation
  end

  def call
    scope = relation.includes(:department, :salary_records)
    scope = apply_search(scope)
    scope = apply_filters(scope)
    scope = apply_sorting(scope)
    paginate(scope)
  end

  private

  def apply_search(scope)
    query = params[:search]&.strip
    return scope if query.blank?

    like_query = "%#{query}%"
    scope.where(
      "employees.employee_code LIKE :q OR employees.first_name LIKE :q OR employees.last_name LIKE :q OR employees.email LIKE :q",
      q: like_query
    )
  end

  def apply_filters(scope)
    scope = scope.where(department_id: params[:department_id]) if params[:department_id].present?
    scope = scope.where(country_code: params[:country_code].to_s.upcase) if params[:country_code].present?
    scope = scope.where(employment_status: params[:employment_status]) if params[:employment_status].present?
    scope
  end

  def apply_sorting(scope)
    sort_key = params[:sort_by].to_s.downcase
    direction = params[:sort_order].to_s.downcase == "desc" ? :desc : :asc

    case sort_key
    when "name"
      scope.order(last_name: direction, first_name: direction)
    when "employee_code"
      scope.order(employee_code: direction)
    when "hire_date"
      scope.order(hire_date: direction)
    when "country_code"
      scope.order(country_code: direction)
    when "employment_status"
      scope.order(employment_status: direction)
    when "department"
      scope.joins(:department).order("departments.name" => direction)
    else
      scope.order(id: :asc)
    end
  end

  def paginate(scope)
    page = [ params[:page].to_i, 1 ].max
    raw_per_page = params[:per_page].present? ? params[:per_page].to_i : DEFAULT_PER_PAGE
    per_page = [ [ raw_per_page, 1 ].max, MAX_PER_PAGE ].min

    total_count = scope.except(:includes, :order).count
    total_pages = (total_count / per_page.to_f).ceil

    records = scope.offset((page - 1) * per_page).limit(per_page)

    {
      records: records,
      meta: {
        page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: total_pages
      }
    }
  end
end
