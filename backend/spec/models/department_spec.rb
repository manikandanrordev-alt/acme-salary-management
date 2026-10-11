require "rails_helper"

RSpec.describe Department, type: :model do
  describe "validations" do
    subject { build(:department) }

    it { is_expected.to be_valid }

    it "requires name" do
      dept = build(:department, name: nil)
      expect(dept).not_to be_valid
    end

    it "validates uniqueness of name" do
      create(:department, name: "Engineering")
      dup = build(:department, name: "Engineering")
      expect(dup).not_to be_valid
    end

    it "requires code" do
      dept = build(:department, code: nil)
      expect(dept).not_to be_valid
    end

    it "validates uniqueness of code" do
      create(:department, code: "ENG")
      dup = build(:department, code: "ENG")
      expect(dup).not_to be_valid
    end
  end

  describe "associations" do
    it "restricts deletion when employees exist" do
      dept = create(:department)
      create(:employee, department: dept)
      expect { dept.destroy }.not_to change(Department, :count)
      expect(dept.errors[:base]).to be_present
    end
  end
end
