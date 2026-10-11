require "rails_helper"

RSpec.describe Payroll::CtcBreakdownService do
  describe ".calculate" do
    it "produces a comprehensive Component A, B, and C breakdown for ₹12,00,000 CTC" do
      result = described_class.calculate(annual_ctc: 1_200_000)

      expect(result[:annual_ctc]).to eq(1_200_000.0)
      expect(result[:component_a_gross][:monthly_total]).to be > 0
      expect(result[:component_a_gross][:breakdown][:basic][:percentage]).to eq(50.0)
      expect(result[:component_b_retirals][:breakdown][:employer_epf][:monthly]).to be > 0
      expect(result[:component_b_retirals][:breakdown][:gratuity_accrual][:monthly]).to be > 0
      expect(result[:employee_take_home][:monthly_net_in_hand]).to be > 0
    end
  end
end
