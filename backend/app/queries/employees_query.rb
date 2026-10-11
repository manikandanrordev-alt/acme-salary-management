class EmployeesQuery
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100

  ALLOWED_SORT_COLUMNS = {
    "employee_code" => "employees.employee_code",
    "name" => "employees.last_name",
    "hire_date" => "employees.hire_date",
    "department" => "departments.name",
    "country_code" => "employees.country_code",
    "employment_status" => "employees.employment_status"
  }.freeze

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
    sort_column = ALLOWED_SORT_COLUMNS[sort_key] || "employees.id"
    sort_direction = params[:sort_order].to_s.downcase == "desc" ? :desc : :asc

    if sort_key == "department"
      scope.joins(:department).order(Arel.sql("#{sort_column} #{sort_direction.to_s.upcase}"))
    else
      scope.order(Arel.sql("#{sort_column} #{sort_direction.to_s.upcase}"))
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
