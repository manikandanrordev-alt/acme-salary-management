class SalaryAuditLog < ApplicationRecord
  belongs_to :salary_record, optional: true
  belongs_to :employee
  belongs_to :user

  ACTIONS = %w[create update supersede terminate].freeze

  validates :action, presence: true, inclusion: { in: ACTIONS }
  validates :new_amount, presence: true, numericality: { greater_than: 0 }
  validates :new_currency, presence: true, length: { is: 3 }
  validates :new_effective_from, presence: true
  validates :change_reason, presence: true

  # Ensure created_at is populated if not explicitly supplied
  before_validation :set_created_at, on: :create

  private

  def set_created_at
    self.created_at ||= Time.current
  end
end
