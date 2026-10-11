# frozen_string_literal: true

module Payroll
  class DiwaliBonusService
    DEFAULT_BONUS_PERCENTAGE = 8.33 # Statutory minimum under Payment of Bonus Act

    def self.calculate_bonus(annual_ctc, bonus_percentage: DEFAULT_BONUS_PERCENTAGE, is_festive_month: false)
      new(annual_ctc, bonus_percentage: bonus_percentage, is_festive_month: is_festive_month).calculate
    end

    def initialize(annual_ctc, bonus_percentage: DEFAULT_BONUS_PERCENTAGE, is_festive_month: false)
      @annual_ctc = [annual_ctc.to_f, 0.0].max
      @bonus_percentage = [bonus_percentage.to_f, 0.0].max
      @is_festive_month = is_festive_month
    end

    def calculate
      annual_basic = @annual_ctc * 0.50
      bonus_amount = if @is_festive_month
                       ((annual_basic * (@bonus_percentage / 100.0))).round(2)
                     else
                       0.0
                     end

      {
        annual_ctc: @annual_ctc.round(2),
        annual_basic: annual_basic.round(2),
        bonus_percentage: @bonus_percentage,
        is_festive_month: @is_festive_month,
        bonus_amount: bonus_amount
      }
    end
  end
end
