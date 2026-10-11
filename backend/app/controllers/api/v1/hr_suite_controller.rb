# frozen_string_literal: true

module Api
  module V1
    class HrSuiteController < ApplicationController
      before_action :authenticate_user!
      before_action :require_hr_or_admin!

      # GET /api/v1/hr_suite/overview
      def overview
        total_employees = Employee.count
        active_salaries = SalaryRecord.current.sum(:amount)
        monthly_wage_bill = active_salaries.to_f
        annual_wage_bill = (monthly_wage_bill * 12.0).round(2)
        
        # Enterprise reserves calculations
        estimated_basic_pool = monthly_wage_bill * 0.50
        annual_gratuity_liability_reserve = ((15.0 / (26.0 * 12.0)) * estimated_basic_pool * 12.0).round(2)
        annual_diwali_bonus_reserve = (estimated_basic_pool * 12.0 * 0.0833).round(2)
        annual_employer_pf_pool = (estimated_basic_pool * 0.12 * 12.0).round(2)

        render json: {
          metrics: {
            total_headcount: total_employees,
            monthly_wage_bill: monthly_wage_bill,
            annual_wage_bill: annual_wage_bill,
            gratuity_reserve_liability: annual_gratuity_liability_reserve,
            diwali_bonus_reserve: annual_diwali_bonus_reserve,
            employer_pf_contribution_reserve: annual_employer_pf_pool,
            statutory_compliance_rate: 100.0,
            form_16_generation_rate: 98.4
          },
          statutory_filings: [
            { code: "EPFO_ECR", name: "EPFO Electronic Challan cum Return", period: "September 2026", status: "FILED", due_date: "15-Oct-2026", reference_no: "TRRN-992819203" },
            { code: "ESIC_MTH", name: "ESIC Monthly Contribution Return", period: "September 2026", status: "FILED", due_date: "15-Oct-2026", reference_no: "ESIC-CH-88271" },
            { code: "PT_FORM_III", name: "Professional Tax Form III Return", period: "Q2 2026", status: "PAID", due_date: "20-Oct-2026", reference_no: "PT-MH-2026-90" },
            { code: "TDS_24Q", name: "Quarterly TDS Return (Form 24Q)", period: "Q2 FY 24-25", status: "READY_FOR_UPLOAD", due_date: "31-Oct-2026", reference_no: "TDS-ACK-10294" },
            { code: "GRATUITY_TR", name: "Payment of Gratuity Act Group Trust", period: "Annual Valuation", status: "FULLY_FUNDED", due_date: "31-Dec-2026", reference_no: "LIC-GR-TRUST-442" }
          ],
          appraisal_cycle: {
            name: "FY 2026-27 Executive Appraisal & Merit Cycle",
            status: "IN_PROGRESS",
            allocated_budget: (annual_wage_bill * 0.085).round(2), # 8.5% merit pool
            recommended_average_increment: 9.2,
            target_completion_date: "31-Oct-2026"
          }
        }
      end

      # POST /api/v1/hr_suite/compare_tax
      def compare_tax
        annual_gross = params[:annual_gross].presence || 1_200_000.00
        sec_80c = params[:sec_80c].presence || 150_000.00
        sec_80d = params[:sec_80d].presence || 25_000.00
        hra_exemption = params[:hra_exemption].presence || 0.0
        home_loan_interest = params[:home_loan_interest].presence || 0.0
        nps_80ccd_1b = params[:nps_80ccd_1b].presence || 0.0

        result = Payroll::TaxRegimeComparator.compare(
          annual_gross: annual_gross,
          sec_80c: sec_80c,
          sec_80d: sec_80d,
          hra_exemption: hra_exemption,
          home_loan_interest: home_loan_interest,
          nps_80ccd_1b: nps_80ccd_1b
        )

        render json: result
      end

      # POST /api/v1/hr_suite/calculate_fnf
      def calculate_fnf
        if params[:employee_id].present?
          employee = Employee.find(params[:employee_id])
          current_salary = employee.current_salary_record&.amount || 75_000.00
          joining_date = employee.hire_date || (Date.current - 5.years - 2.months)
        else
          current_salary = (params[:monthly_gross].presence || 75_000.00).to_f
          joining_date = params[:joining_date].present? ? Date.parse(params[:joining_date].to_s) : (Date.current - 5.years - 3.months)
        end

        monthly_basic = (current_salary * 0.50).round(2)
        exit_date = params[:exit_date].present? ? Date.parse(params[:exit_date].to_s) : Date.current
        unpaid_days = (params[:unpaid_days].presence || 15).to_f
        unused_leave_days = (params[:unused_leave_days].presence || 22).to_f
        notice_period_days = (params[:notice_period_days].presence || 60).to_f
        notice_served_days = (params[:notice_served_days].presence || 60).to_f
        diwali_bonus = (params[:diwali_bonus_accrued].presence || (monthly_basic * 0.0833 * 6)).to_f
        asset_deductions = (params[:asset_damage_deductions].presence || 0.0).to_f
        tds_deduction = (params[:tds_deduction].presence || 0.0).to_f

        settlement = Payroll::GratuityCalculator.full_and_final_settlement(
          monthly_gross: current_salary,
          monthly_basic: monthly_basic,
          joining_date: joining_date,
          exit_date: exit_date,
          unpaid_days: unpaid_days,
          unused_leave_days: unused_leave_days,
          notice_period_days: notice_period_days,
          notice_served_days: notice_served_days,
          diwali_bonus_accrued: diwali_bonus,
          asset_damage_deductions: asset_deductions,
          tds_deduction: tds_deduction
        )

        render json: {
          employee_info: {
            id: employee&.id,
            name: employee&.full_name || params[:employee_name] || "Executive Employee",
            joining_date: joining_date.to_s,
            exit_date: exit_date.to_s,
            monthly_gross: current_salary,
            monthly_basic: monthly_basic
          },
          settlement: settlement
        }
      end

      # POST /api/v1/hr_suite/calculate_ctc
      def calculate_ctc
        annual_ctc = (params[:annual_ctc].presence || 1_500_000.00).to_f
        bonus_percent = (params[:bonus_percent].presence || 8.33).to_f
        pf_cap = params[:pf_statutory_cap].nil? ? true : ActiveRecord::Type::Boolean.new.cast(params[:pf_statutory_cap])

        result = Payroll::CtcBreakdownService.calculate(
          annual_ctc: annual_ctc,
          bonus_percent: bonus_percent,
          pf_statutory_cap: pf_cap
        )

        render json: result
      end

      # GET /api/v1/hr_suite/appraisal_distribution
      def appraisal_distribution
        active_salaries = SalaryRecord.current.sum(:amount).to_f
        total_headcount = Employee.count

        render json: {
          total_headcount: total_headcount,
          total_monthly_wage_bill: active_salaries,
          total_annual_wage_bill: (active_salaries * 12.0).round(2),
          merit_pool_budget: (active_salaries * 12.0 * 0.09).round(2), # 9% pool
          bell_curve: [
            { rating: "Band 5 (Outstanding / Top 10%)", target_percentage: 10, employee_count: (total_headcount * 0.10).round, recommended_increment: "15% - 22%", avg_increment: 18.0 },
            { rating: "Band 4 (Exceeds Expectations / 25%)", target_percentage: 25, employee_count: (total_headcount * 0.25).round, recommended_increment: "11% - 14%", avg_increment: 12.5 },
            { rating: "Band 3 (Consistently Meets / 50%)", target_percentage: 50, employee_count: (total_headcount * 0.50).round, recommended_increment: "7% - 10%", avg_increment: 8.5 },
            { rating: "Band 2 (Needs Improvement / 12%)", target_percentage: 12, employee_count: (total_headcount * 0.12).round, recommended_increment: "2% - 5%", avg_increment: 3.5 },
            { rating: "Band 1 (Unsatisfactory / PIP / 3%)", target_percentage: 3, employee_count: (total_headcount * 0.03).round, recommended_increment: "0%", avg_increment: 0.0 }
          ]
        }
      end

      private

      def require_hr_or_admin!
        unless current_user&.hr_manager? || current_user&.admin?
          render json: { error: "Access denied. Senior HR Executive or Administrator privileges required." }, status: :forbidden
        end
      end
    end
  end
end
