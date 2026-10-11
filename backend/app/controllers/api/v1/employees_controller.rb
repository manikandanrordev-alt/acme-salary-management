module Api
  module V1
    class EmployeesController < ApplicationController
      before_action :authenticate_user!
      before_action :set_employee, only: [ :show ]

      # GET /api/v1/employees
      def index
        query_result = EmployeesQuery.new(filter_params).call

        render json: {
          data: EmployeeSerializer.render_collection(query_result[:records]),
          meta: query_result[:meta]
        }, status: :ok
      end

      # GET /api/v1/employees/:id
      def show
        render json: {
          data: EmployeeSerializer.render_detail(@employee)
        }, status: :ok
      end

      private

      def set_employee
        @employee = Employee.includes(:department, :salary_records).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: {
            code: "NOT_FOUND",
            message: "Employee not found with id #{params[:id]}"
          }
        }, status: :not_found
      end

      def filter_params
        params.permit(
          :page,
          :per_page,
          :search,
          :department_id,
          :country_code,
          :employment_status,
          :sort_by,
          :sort_order
        )
      end
    end
  end
end
