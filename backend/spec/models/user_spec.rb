require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to be_valid }

    it "requires an email" do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to be_present
    end

    it "validates uniqueness of email" do
      create(:user, email: "duplicate@acme.com")
      duplicate = build(:user, email: "duplicate@acme.com")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:email]).to be_present
    end

    it "validates email format" do
      invalid = build(:user, email: "not-an-email")
      expect(invalid).not_to be_valid
    end

    it "requires full_name" do
      user = build(:user, full_name: nil)
      expect(user).not_to be_valid
    end

    it "requires valid role" do
      invalid_role = build(:user, role: "super_hacker")
      expect(invalid_role).not_to be_valid
    end
  end

  describe "password hashing and verification" do
    it "encrypts password and verifies valid credentials" do
      user = create(:user, password: "SecretPassword123!")
      expect(user.encrypted_password).not_to eq("SecretPassword123!")
      expect(user.valid_password?("SecretPassword123!")).to be true
      expect(user.valid_password?("WrongPassword")).to be false
    end
  end
end
