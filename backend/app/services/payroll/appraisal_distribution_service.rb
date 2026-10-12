# frozen_string_literal: true

module Payroll
  class AppraisalDistributionService
    DEFAULT_TIER_CONFIG = [
      { rating: "Band 5 (Outstanding / Top 10%)", target_percentage: 10, recommended_increment: "15% - 20%", avg_increment: 16.0 },
      { rating: "Band 4 (Exceeds Expectations / 25%)", target_percentage: 25, recommended_increment: "11% - 14%", avg_increment: 11.5 },
      { rating: "Band 3 (Consistently Meets / 50%)", target_percentage: 50, recommended_increment: "7% - 10%", avg_increment: 8.0 },
      { rating: "Band 2 (Needs Improvement / 12%)", target_percentage: 12, recommended_increment: "2% - 5%", avg_increment: 2.5 },
      { rating: "Band 1 (Unsatisfactory / PIP / 3%)", target_percentage: 3, recommended_increment: "0%", avg_increment: 0.0 }
    ].freeze

    APPROVED_BUDGET_PERCENTAGE = 9.0

    def self.calculate(currency: nil, records: nil, tier_config: nil)
      new(currency: currency, records: records, tier_config: tier_config).calculate
    end

    def initialize(currency: nil, records: nil, tier_config: nil)
      @currency = currency.presence
      @records = records || scoped_records
      @tier_config = tier_config || DEFAULT_TIER_CONFIG
    end

    def calculate
      ordered_records = @records.to_a
      total_headcount = ordered_records.size

      return empty_response if total_headcount.zero?

      annual_wage_bill = ordered_records.sum { |r| extract_amount(r) }.round(2)
      monthly_wage_bill = (annual_wage_bill / 12.0).round(2)
      approved_budget = (annual_wage_bill * (APPROVED_BUDGET_PERCENTAGE / 100.0)).round(2)

      has_assigned_bands = ordered_records.any? { |r| record_band(r).present? }

      bell_curve = if has_assigned_bands
        calculate_tiers_from_assigned_records(ordered_records, total_headcount, annual_wage_bill)
      else
        project_tiers_from_assumed_shares(ordered_records, total_headcount, annual_wage_bill)
      end

      projected_cost = bell_curve.sum { |t| t[:projected_cost] }.round(2)
      reserve_buffer = (approved_budget - projected_cost).round(2)
      salary_weighted_rate = annual_wage_bill.positive? ? ((projected_cost / annual_wage_bill) * 100.0).round(2) : 0.0
      is_budget_exceeded = projected_cost > approved_budget

      {
        total_headcount: total_headcount,
        total_monthly_wage_bill: monthly_wage_bill,
        total_annual_wage_bill: annual_wage_bill,
        merit_pool_budget: approved_budget,
        approved_budget_percentage: APPROVED_BUDGET_PERCENTAGE,
        salary_weighted_increment_rate: salary_weighted_rate,
        projected_increment_cost: projected_cost,
        reserve_buffer_surplus: reserve_buffer,
        is_budget_exceeded: is_budget_exceeded,
        recommended_average_increment: APPROVED_BUDGET_PERCENTAGE,
        period: "annual",
        currency: @currency || "INR",
        is_projection: !has_assigned_bands,
        calculation_type: has_assigned_bands ? "actual_band_assignment" : "projection_model",
        methodology: has_assigned_bands ? "actual_employee_band_assignment" : "assumed_salary_shares",
        methodology_disclaimer: has_assigned_bands ?
          "Calculated from actual annual salary records assigned to each performance band." :
          "Projection based on assumed salary shares (target distribution quotas) across annual wage bill. Actual employee-level performance-band assignments are not implemented in the salary dataset.",
        bell_curve: bell_curve
      }
    end

    private

    def scoped_records
      scope = SalaryRecord.current.order(:id)
      scope = scope.where(currency: @currency) if @currency.present?
      scope
    end

    def extract_amount(record)
      if record.is_a?(Hash)
        (record[:amount] || record["amount"]).to_f
      elsif record.respond_to?(:amount)
        record.amount.to_f
      else
        0.0
      end
    end

    def record_band(record)
      if record.is_a?(Hash)
        record[:performance_band] || record[:rating] || record[:band] || record["performance_band"] || record["rating"]
      elsif record.respond_to?(:performance_band) && record.performance_band.present?
        record.performance_band
      elsif record.respond_to?(:rating) && record.rating.present?
        record.rating
      elsif record.respond_to?(:band) && record.band.present?
        record.band
      end
    end

    def record_matches_tier?(record, tier, idx)
      band_val = record_band(record).to_s.strip.downcase
      return false if band_val.blank?

      tier_rating = tier[:rating].to_s.downcase
      tier_num = (5 - idx).to_s

      band_val == tier_rating ||
        band_val == "band #{tier_num}" ||
        band_val == "band_#{tier_num}" ||
        band_val == tier_num ||
        band_val.start_with?("band #{tier_num}")
    end

    def calculate_tiers_from_assigned_records(ordered_records, _total_headcount, annual_wage_bill)
      @tier_config.each_with_index.map do |tier, idx|
        band_records = ordered_records.select { |r| record_matches_tier?(r, tier, idx) }
        tier_count = band_records.size
        tier_salary = band_records.sum { |r| extract_amount(r) }.round(2)
        tier_cost = (tier_salary * (tier[:avg_increment] / 100.0)).round(2)
        salary_share_pct = annual_wage_bill.positive? ? ((tier_salary / annual_wage_bill) * 100.0).round(2) : 0.0

        {
          rating: tier[:rating],
          target_percentage: tier[:target_percentage],
          employee_count: tier_count,
          actual_tier_wage_bill: tier_salary,
          salary_share_percentage: salary_share_pct,
          recommended_increment: tier[:recommended_increment],
          avg_increment: tier[:avg_increment],
          projected_cost: tier_cost
        }
      end
    end

    def project_tiers_from_assumed_shares(_ordered_records, total_headcount, annual_wage_bill)
      allocated_salary = 0.0
      allocated_headcount = 0

      @tier_config.each_with_index.map do |tier, idx|
        is_last = (idx == @tier_config.size - 1)

        tier_count = if is_last
          [ total_headcount - allocated_headcount, 0 ].max
        else
          (total_headcount * (tier[:target_percentage] / 100.0)).round
        end
        allocated_headcount += tier_count

        tier_salary = if is_last
          (annual_wage_bill - allocated_salary).round(2)
        else
          (annual_wage_bill * (tier[:target_percentage] / 100.0)).round(2)
        end
        allocated_salary = (allocated_salary + tier_salary).round(2)

        tier_cost = (tier_salary * (tier[:avg_increment] / 100.0)).round(2)
        salary_share_pct = annual_wage_bill.positive? ? ((tier_salary / annual_wage_bill) * 100.0).round(2) : 0.0

        {
          rating: tier[:rating],
          target_percentage: tier[:target_percentage],
          employee_count: tier_count,
          actual_tier_wage_bill: tier_salary,
          salary_share_percentage: salary_share_pct,
          recommended_increment: tier[:recommended_increment],
          avg_increment: tier[:avg_increment],
          projected_cost: tier_cost
        }
      end
    end

    def empty_response
      {
        total_headcount: 0,
        total_monthly_wage_bill: 0.0,
        total_annual_wage_bill: 0.0,
        merit_pool_budget: 0.0,
        approved_budget_percentage: APPROVED_BUDGET_PERCENTAGE,
        salary_weighted_increment_rate: 0.0,
        projected_increment_cost: 0.0,
        reserve_buffer_surplus: 0.0,
        is_budget_exceeded: false,
        recommended_average_increment: APPROVED_BUDGET_PERCENTAGE,
        period: "annual",
        currency: @currency || "INR",
        is_projection: true,
        calculation_type: "projection_model",
        methodology: "assumed_salary_shares",
        methodology_disclaimer: "No salary records found for the specified scope.",
        bell_curve: []
      }
    end
  end
end
