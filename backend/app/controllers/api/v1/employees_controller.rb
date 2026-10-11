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

      # GET /api/v1/employees/export
      def export
        csv_data = EmployeeCsvExportService.new(filter_params).call
        filename = "acme_employees_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv"

        send_data csv_data,
                  filename: filename,
                  type: "text/csv; charset=utf-8",
                  disposition: "attachment"
      end

      # POST /api/v1/employees/import
      def import
        require_hr_manager!
        return if performed?

        csv_content = if params[:file].present?
                        params[:file].read
        elsif params[:csv].present?
                        params[:csv].to_s
        else
                        request.body.read
        end

        if csv_content.blank?
          render json: {
            error: {
              code: "MISSING_FILE",
              message: "Please upload a CSV file or provide CSV text content"
            }
          }, status: :unprocessable_entity
          return
        end

        result = EmployeeCsvImportService.new(
          csv_data: csv_content,
          current_user: current_user,
          client_info: {
            ip_address: request.remote_ip,
            user_agent: request.user_agent
          }
        ).call

        status = result[:created_count].positive? ? :ok : :unprocessable_entity

        render json: {
          data: result,
          message: "Processed #{result[:total_rows]} rows, created #{result[:created_count]} employees"
        }, status: status
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
