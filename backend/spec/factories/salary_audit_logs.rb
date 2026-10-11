FactoryBot.define do
  factory :salary_audit_log do
    association :salary_record
    association :employee
    association :user
    action { "create" }
    new_amount { 95_000.00 }
    new_currency { "USD" }
    new_effective_from { Date.current - 1.year }
    change_reason { "initial_hire" }
    created_at { Time.current }
  end
end
