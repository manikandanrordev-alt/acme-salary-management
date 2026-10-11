module Api
  module V1
    class SalaryRevisionsController < ApplicationController
      before_action :authenticate_user!
      before_action :require_hr_manager!
      before_action :set_employee

      # POST /api/v1/employees/:employee_id/salary_revisions
      def create
        service = SalaryRevisionService.new(
          employee: @employee,
          params: revision_params,
          current_user: current_user,
          client_info: {
            ip_address: request.remote_ip,
            user_agent: request.user_agent
          }
        )

        new_record = service.call

        render json: {
          data: EmployeeSerializer.render_salary(new_record),
          message: "Salary revision recorded successfully"
        }, status: :created
      rescue SalaryRevisionService::RevisionError => e
        render json: {
          error: {
            code: "REVISION_FAILED",
            message: e.message
          }
        }, status: :unprocessable_entity
      end

      private

      def set_employee
        @employee = Employee.find(params[:employee_id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          error: {
            code: "NOT_FOUND",
            message: "Employee not found with id #{params[:employee_id]}"
          }
        }, status: :not_found
      end

      def revision_params
        params.permit(:amount, :currency, :effective_from, :change_reason, :pay_frequency)
      end
    end
  end
end
