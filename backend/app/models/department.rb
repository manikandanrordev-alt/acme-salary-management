class Department < ApplicationRecord
  has_many :employees, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: true
  validates :code, presence: true, uniqueness: true, format: { with: /\A[A-Z0-9_-]+\z/, message: "must be uppercase letters, numbers, hyphens or underscores" }
end
