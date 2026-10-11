FactoryBot.define do
  factory :salary_record do
    association :employee
    amount { 95_000.00 }
    currency { "USD" }
    effective_from { Date.current - 1.year }
    effective_to { nil }
    pay_frequency { "annual" }
    change_reason { "initial_hire" }
  end
end
