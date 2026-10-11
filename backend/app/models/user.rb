class User < ApplicationRecord
  has_many :salary_audit_logs, dependent: :restrict_with_error

  ROLES = %w[admin hr_manager auditor].freeze

  validates :email, presence: true, uniqueness: { case_sensitive: false }, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :full_name, presence: true
  validates :role, presence: true, inclusion: { in: ROLES }
  validates :encrypted_password, presence: true

  def password=(raw_password)
    if raw_password.present?
      self.encrypted_password = BCrypt::Password.create(raw_password)
    end
  end

  def valid_password?(raw_password)
    return false if encrypted_password.blank?

    BCrypt::Password.new(encrypted_password) == raw_password
  rescue BCrypt::Errors::InvalidHash
    false
  end
end
