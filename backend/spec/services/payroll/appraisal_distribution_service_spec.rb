# frozen_string_literal: true

require "rails_helper"

RSpec.describe Payroll::AppraisalDistributionService do
  # Ruby Struct for lightweight hermetic record mocking without DB dependency
  let(:mock_record_class) do
    Struct.new(:amount, :currency, :performance_band, keyword_init: true)
  end

  describe ".calculate" do
    let(:sample_records_with_bands) do
      [
        # Band 5: 1 employee @ 400,000
        mock_record_class.new(amount: 400_000.0, currency: "INR", performance_band: "Band 5"),
        # Band 4: 2 employees @ 400,000 each = 800,000
        mock_record_class.new(amount: 400_000.0, currency: "INR", performance_band: "Band 4"),
        mock_record_class.new(amount: 400_000.0, currency: "INR", performance_band: "Band 4"),
        # Band 3: 5 employees @ 350,000 each = 1,750,000
        mock_record_class.new(amount: 350_000.0, currency: "INR", performance_band: "Band 3"),
        mock_record_class.new(amount: 350_000.0, currency: "INR", performance_band: "Band 3"),
        mock_record_class.new(amount: 350_000.0, currency: "INR", performance_band: "Band 3"),
        mock_record_class.new(amount: 350_000.0, currency: "INR", performance_band: "Band 3"),
        mock_record_class.new(amount: 350_000.0, currency: "INR", performance_band: "Band 3"),
        # Band 2: 1 employee @ 350,000 = 350,000
        mock_record_class.new(amount: 350_000.0, currency: "INR", performance_band: "Band 2"),
        # Band 1: 1 employee @ 300,000 = 300,000
        mock_record_class.new(amount: 300_000.0, currency: "INR", performance_band: "Band 1")
      ]
    end

    let(:unassigned_records) do
      Array.new(10) { mock_record_class.new(amount: 350_000.0, currency: "INR") }
    end

    it "calculates increment costs from actual salary records assigned to each performance band" do
      result = described_class.calculate(records: sample_records_with_bands, currency: "INR")

      expect(result[:is_projection]).to be(false)
      expect(result[:calculation_type]).to eq("actual_band_assignment")
      expect(result[:methodology]).to eq("actual_employee_band_assignment")
      expect(result[:total_headcount]).to eq(10)
      expect(result[:total_annual_wage_bill]).to eq(3_600_000.0)

      # 9% merit pool budget on 3.6M wage bill = 324,000
      expected_budget = (3_600_000.0 * 0.09).round(2)
      expect(result[:merit_pool_budget]).to eq(expected_budget)

      # Verify Band 5: 1 employee, 400k wage bill, 16.0% increment = 64,000
      b5 = result[:bell_curve].find { |t| t[:rating].include?("Band 5") }
      expect(b5[:employee_count]).to eq(1)
      expect(b5[:actual_tier_wage_bill]).to eq(400_000.0)
      expect(b5[:projected_cost]).to eq(64_000.0)

      # Reconcile sum of tier costs and reserve
      tier_costs_sum = result[:bell_curve].sum { |t| t[:projected_cost] }.round(2)
      expect(result[:projected_increment_cost]).to eq(tier_costs_sum)
      expect(result[:reserve_buffer_surplus]).to eq((expected_budget - tier_costs_sum).round(2))
      expect(result[:is_budget_exceeded]).to be(false)
    end

    it "clearly identifies calculation as projection based on assumed salary shares when bands are unassigned" do
      result = described_class.calculate(records: unassigned_records, currency: "INR")

      expect(result[:is_projection]).to be(true)
      expect(result[:calculation_type]).to eq("projection_model")
      expect(result[:methodology]).to eq("assumed_salary_shares")
      expect(result[:methodology_disclaimer]).to include("Projection based on assumed salary shares")
      expect(result[:total_headcount]).to eq(10)
      expect(result[:total_annual_wage_bill]).to eq(3_500_000.0)

      expected_budget = 315_000.0 # 9% of 3.5M
      expect(result[:merit_pool_budget]).to eq(expected_budget)
      expect(result[:projected_increment_cost]).to be <= expected_budget
      expect(result[:reserve_buffer_surplus]).to be >= 0.0
      expect(result[:is_budget_exceeded]).to be(false)

      # Sum of tier wage bills must exactly equal total annual wage bill
      tier_wages_sum = result[:bell_curve].sum { |t| t[:actual_tier_wage_bill] }.round(2)
      expect(tier_wages_sum).to eq(result[:total_annual_wage_bill])

      # Sum of tier costs must exactly equal projected increment cost
      tier_costs_sum = result[:bell_curve].sum { |t| t[:projected_cost] }.round(2)
      expect(tier_costs_sum).to eq(result[:projected_increment_cost])
    end

    it "calculates approved 9% budget, projected increment cost, weighted rate, and reserve from the same dataset" do
      records = Array.new(20) { mock_record_class.new(amount: 500_000.0, currency: "INR") }
      result = described_class.calculate(records: records, currency: "INR")

      total_wage = 10_000_000.0
      budget = 900_000.0

      expect(result[:total_annual_wage_bill]).to eq(total_wage)
      expect(result[:merit_pool_budget]).to eq(budget)
      expect(result[:approved_budget_percentage]).to eq(9.0)

      # Math reconciliation
      expected_projected = result[:bell_curve].sum { |t| t[:projected_cost] }.round(2)
      expect(result[:projected_increment_cost]).to eq(expected_projected)
      expect(result[:reserve_buffer_surplus]).to eq((budget - expected_projected).round(2))
      expect(result[:salary_weighted_increment_rate]).to eq(((expected_projected / total_wage) * 100.0).round(2))
    end

    it "dynamically responds when underlying salary records change" do
      small_records = [ mock_record_class.new(amount: 1_000_000.0, currency: "INR") ]
      large_records = [ mock_record_class.new(amount: 5_000_000.0, currency: "INR") ]

      small_result = described_class.calculate(records: small_records, currency: "INR")
      large_result = described_class.calculate(records: large_records, currency: "INR")

      expect(small_result[:merit_pool_budget]).to eq(90_000.0)
      expect(large_result[:merit_pool_budget]).to eq(450_000.0)
      expect(large_result[:projected_increment_cost]).to be > small_result[:projected_increment_cost]
    end

    it "detects and flags budget-overrun when band distribution rates exceed approved budget" do
      overrun_tier_config = [
        { rating: "Band 5 (Top 10%)", target_percentage: 10, recommended_increment: "25%", avg_increment: 25.0 },
        { rating: "Band 4 (Exceeds 25%)", target_percentage: 25, recommended_increment: "18%", avg_increment: 18.0 },
        { rating: "Band 3 (Meets 50%)", target_percentage: 50, recommended_increment: "12%", avg_increment: 12.0 },
        { rating: "Band 2 (Needs Imp 12%)", target_percentage: 12, recommended_increment: "6%", avg_increment: 6.0 },
        { rating: "Band 1 (PIP 3%)", target_percentage: 3, recommended_increment: "0%", avg_increment: 0.0 }
      ]

      result = described_class.calculate(records: unassigned_records, tier_config: overrun_tier_config)

      expect(result[:is_budget_exceeded]).to be(true)
      expect(result[:projected_increment_cost]).to be > result[:merit_pool_budget]
      expect(result[:reserve_buffer_surplus]).to be < 0.0
      expect(result[:salary_weighted_increment_rate]).to be > 9.0
    end

    it "handles empty records gracefully by returning zeroed metrics" do
      result = described_class.calculate(records: [])

      expect(result[:total_headcount]).to eq(0)
      expect(result[:total_annual_wage_bill]).to eq(0.0)
      expect(result[:merit_pool_budget]).to eq(0.0)
      expect(result[:projected_increment_cost]).to eq(0.0)
      expect(result[:reserve_buffer_surplus]).to eq(0.0)
      expect(result[:is_budget_exceeded]).to be(false)
      expect(result[:bell_curve]).to be_empty
    end
  end
end
