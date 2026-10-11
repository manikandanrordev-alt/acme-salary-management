FactoryBot.define do
  factory :department do
    sequence(:name) { |n| "Department #{n}" }
    sequence(:code) { |n| "DEP#{n}" }
  end
end
