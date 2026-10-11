# frozen_string_literal: true

module Api
  module V1
    class PayslipsController < ApplicationController
      before_action :authenticate_user!
      before_action :require_hr_manager!, only: %i[generate_batch send_email send_batch_emails]
      before_action :set_payslip, only: %i[show send_email]

      # GET /api/v1/payslips
      def index
        scope = Payslip.includes(employee: [ :department, :salary_records ]).recent

        if params[:payroll_month].present?
          scope = scope.where(payroll_month: params[:payroll_month])
        end

        if params[:department_id].present?
          scope = scope.joins(:employee).where(employees: { department_id: params[:department_id] })
        end

        if params[:search].present?
          term = "%#{params[:search].strip}%"
          scope = scope.joins(:employee).where(
            "employees.employee_code LIKE ? OR employees.first_name LIKE ? OR employees.last_name LIKE ? OR employees.email LIKE ?",
            term, term, term, term
          )
        end

        total_count = scope.count
        page = [ params[:page].to_i, 1 ].max
        per_page = [ [ params[:per_page].to_i, 1 ].max, 100 ].min
        per_page = 25 if per_page <= 0

        payslips = scope.offset((page - 1) * per_page).limit(per_page)

        # Monthly summary metrics
        month_filter = params[:payroll_month].presence || payslips.first&.payroll_month
        summary_scope = month_filter ? Payslip.where(payroll_month: month_filter) : Payslip.all

        metrics = {
          total_payslips: summary_scope.count,
          total_gross_inr: summary_scope.sum(:gross_earnings).to_f.round(2),
          total_net_disbursed_inr: summary_scope.sum(:net_pay).to_f.round(2),
          total_tds_tax_inr: summary_scope.sum(:tds_tax_deduction).to_f.round(2),
          total_epf_inr: summary_scope.sum(:epf_deduction).to_f.round(2),
          total_diwali_bonus_inr: summary_scope.sum(:diwali_bonus).to_f.round(2),
          total_dispatched_emails: summary_scope.where(status: "dispatched").count
        }

        render json: {
          data: PayslipSerializer.render_collection(payslips),
          meta: {
            page: page,
            per_page: per_page,
            total_count: total_count,
            total_pages: (total_count.to_f / per_page).ceil,
            currency: "INR"
          },
          summary: metrics
        }, status: :ok
      end

      # GET /api/v1/payslips/:id
      def show
        render json: {
          data: PayslipSerializer.render(@payslip)
        }, status: :ok
      end

      # POST /api/v1/payslips/generate_batch
      def generate_batch
        month = params[:payroll_month].presence || Date.current.strftime("%Y-%m")
        include_bonus = ActiveModel::Type::Boolean.new.cast(params[:include_diwali_bonus])
        bonus_pct = params[:bonus_percentage].to_f > 0 ? params[:bonus_percentage].to_f : 8.33
        limit = [ params[:limit].to_i, 1000 ].min
        limit = 100 if limit <= 0

        employees = Employee.where(employment_status: "active").limit(limit)
        generated_count = 0
        errors = []

        employees.find_each do |employee|
          begin
            # Synthesize realistic sample LOP days (0 to 2) for variety
            sample_lop = (employee.id % 7 == 0) ? 1 : 0
            sample_bonus = include_bonus || [ 10, 11 ].include?(month.split("-").last.to_i)

            Payroll::PayslipGenerator.generate_for_employee(
              employee,
              payroll_month: month,
              lop_days: sample_lop,
              include_diwali_bonus: sample_bonus,
              bonus_percentage: bonus_pct
            )
            generated_count += 1
          rescue StandardError => e
            errors << { employee_code: employee.employee_code, error: e.message }
          end
        end

        render json: {
          message: "Payroll run completed: generated #{generated_count} payslips for #{month}",
          data: {
            payroll_month: month,
            generated_count: generated_count,
            errors_count: errors.size,
            errors: errors.first(10)
          }
        }, status: :created
      end

      # POST /api/v1/payslips/:id/send_email
      def send_email
        begin
          PayslipMailer.send_payslip(@payslip.id).deliver_now
          @payslip.mark_as_emailed!

          render json: {
            message: "Payslip email dispatched successfully to #{@payslip.email_recipient}",
            data: PayslipSerializer.render(@payslip)
          }, status: :ok
        rescue StandardError => e
          render json: {
            error: {
              code: "EMAIL_DISPATCH_FAILED",
              message: "Failed to dispatch email: #{e.message}"
            }
          }, status: :internal_server_error
        end
      end

      # POST /api/v1/payslips/send_batch_emails
      def send_batch_emails
        month = params[:payroll_month].presence || Date.current.strftime("%Y-%m")
        payslips = Payslip.includes(:employee).where(payroll_month: month).where.not(status: "dispatched").limit(50)

        dispatched_count = 0
        payslips.each do |payslip|
          begin
            PayslipMailer.send_payslip(payslip.id).deliver_now
            payslip.mark_as_emailed!
            dispatched_count += 1
          rescue StandardError => _e
            # continue with remaining batch
          end
        end

        render json: {
          message: "Batch email dispatch completed: sent #{dispatched_count} payslips for #{month}",
          data: {
            payroll_month: month,
            dispatched_count: dispatched_count,
            remaining_undispatched: Payslip.where(payroll_month: month).where.not(status: "dispatched").count
          }
        }, status: :ok
      end

      private

      def set_payslip
        @payslip = Payslip.includes(employee: [ :department, :salary_records ]).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: { code: "NOT_FOUND", message: "Payslip not found" } }, status: :not_found
      end
    end
  end
end
