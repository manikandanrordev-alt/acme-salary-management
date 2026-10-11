class SalaryRecord < ApplicationRecord
  belongs_to :employee, inverse_of: :salary_records
  has_many :salary_audit_logs, dependent: :nullify

  PAY_FREQUENCIES = %w[annual monthly].freeze

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :currency, presence: true, length: { is: 3 }, format: { with: /\A[A-Z]{3}\z/, message: "must be 3 uppercase letters" }
  validates :effective_from, presence: true
  validates :pay_frequency, presence: true, inclusion: { in: PAY_FREQUENCIES }
  validates :change_reason, presence: true
  validate :validate_effective_date_order
  validate :validate_non_overlapping_dates, if: -> { employee.present? && effective_from.present? }

  scope :current, -> {
    where("effective_from <= ? AND (effective_to IS NULL OR effective_to >= ?)", Date.current, Date.current)
  }

  scope :effective_on, ->(date) {
    where("effective_from <= ? AND (effective_to IS NULL OR effective_to >= ?)", date, date)
  }

  def current?
    today = Date.current
    effective_from <= today && (effective_to.nil? || effective_to >= today)
  end

  private

  def validate_effective_date_order
    return if effective_to.blank? || effective_from.blank?

    if effective_to < effective_from
      errors.add(:effective_to, "cannot precede effective_from date")
    end
  end

  def validate_non_overlapping_dates
    scope = employee.salary_records
    scope = scope.where.not(id: id) if persisted?

    overlapping = if effective_to.present?
      scope.where(
        "effective_from <= ? AND (effective_to IS NULL OR effective_to >= ?)",
        effective_to,
        effective_from
      )
    else
      scope.where("effective_to IS NULL OR effective_to >= ?", effective_from)
    end

    if overlapping.exists?
      errors.add(:base, "Salary effective date range overlaps with an existing record for this employee")
    end
  end
end
