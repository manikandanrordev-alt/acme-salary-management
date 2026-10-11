class Employee < ApplicationRecord
  belongs_to :department
  has_many :salary_records, -> { order(effective_from: :asc) }, dependent: :destroy, inverse_of: :employee
  has_many :salary_audit_logs, dependent: :restrict_with_error
  has_many :payslips, dependent: :destroy

  STATUSES = %w[active on_leave terminated].freeze

  validates :employee_code, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :country_code, presence: true, length: { in: 2..3 }
  validates :employment_status, presence: true, inclusion: { in: STATUSES }
  validates :hire_date, presence: true
  validate :validate_termination_date

  def full_name
    "#{first_name} #{last_name}"
  end

  def current_salary_record
    salary_records.where(
      "effective_from <= ? AND (effective_to IS NULL OR effective_to >= ?)",
      Date.current,
      Date.current
    ).order(effective_from: :desc).first
  end

  private

  def validate_termination_date
    return if termination_date.blank? || hire_date.blank?

    if termination_date < hire_date
      errors.add(:termination_date, "cannot precede hire date")
    end
  end
end
