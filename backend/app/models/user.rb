class User < ApplicationRecord
  devise :database_authenticatable, :validatable

  has_many :salary_audit_logs, dependent: :restrict_with_error

  ROLES = %w[admin hr_manager auditor].freeze

  validates :full_name, presence: true
  validates :role, presence: true, inclusion: { in: ROLES }

  def hr_manager?
    role == "hr_manager"
  end

  def admin?
    role == "admin"
  end

  def auditor?
    role == "auditor"
  end
end
