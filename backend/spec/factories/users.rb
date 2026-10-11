FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user_#{n}@acme.com" }
    full_name { "HR Manager" }
    role { "hr_manager" }
    password { "Password123!" }
  end
end
