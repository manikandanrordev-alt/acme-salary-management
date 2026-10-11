FactoryBot.define do
  factory :employee do
    association :department
    sequence(:employee_code) { |n| "ACME-%05d" % n }
    first_name { "Jane" }
    last_name { "Doe" }
    sequence(:email) { |n| "employee_#{n}@acme.com" }
    country_code { "US" }
    employment_status { "active" }
    hire_date { Date.current - 2.years }
  end
end
