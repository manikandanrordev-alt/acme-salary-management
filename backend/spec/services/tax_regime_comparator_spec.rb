require "rails_helper"

RSpec.describe Payroll::TaxRegimeComparator do
  describe ".compare" do
    it "recommends New Regime when deductions are minimal" do
      result = described_class.compare(
        annual_gross: 1_200_000,
        sec_80c: 50_000,
        sec_80d: 10_000,
        hra_exemption: 0
      )

      expect(result[:recommended_regime]).to eq("NEW_REGIME")
      expect(result[:new_regime][:standard_deduction]).to eq(75_000.0)
      expect(result[:annual_tax_difference]).to be > 0
    end

    it "recommends Old Regime when substantial deductions (80C, 80D, HRA) exceed breakeven threshold" do
      result = described_class.compare(
        annual_gross: 1_500_000,
        sec_80c: 150_000,
        sec_80d: 50_000,
        hra_exemption: 240_000,
        home_loan_interest: 150_000
      )

      # Deductions total: 50k (std) + 150k + 50k + 240k + 150k = 640k -> Taxable income: 860k
      expect(result[:recommended_regime]).to eq("OLD_REGIME")
      expect(result[:old_regime][:total_deductions]).to eq(640_000.0)
      expect(result[:annual_tax_difference]).to be > 0
    end
  end
end
