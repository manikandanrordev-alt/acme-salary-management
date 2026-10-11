require "rails_helper"

RSpec.describe SalaryAuditLog, type: :model do
  describe "validations" do
    subject { build(:salary_audit_log) }

    it { is_expected.to be_valid }

    it "requires valid action" do
      invalid = build(:salary_audit_log, action: "unauthorized_action")
      expect(invalid).not_to be_valid
    end

    it "requires positive new_amount" do
      invalid = build(:salary_audit_log, new_amount: 0)
      expect(invalid).not_to be_valid
    end

    it "requires new_currency" do
      invalid = build(:salary_audit_log, new_currency: nil)
      expect(invalid).not_to be_valid
    end

    it "requires new_effective_from" do
      invalid = build(:salary_audit_log, new_effective_from: nil)
      expect(invalid).not_to be_valid
    end

    it "requires change_reason" do
      invalid = build(:salary_audit_log, change_reason: nil)
      expect(invalid).not_to be_valid
    end
  end

  describe "associations" do
    let(:log) { create(:salary_audit_log) }

    it "belongs to employee, user, and optional salary_record" do
      expect(log.employee).to be_present
      expect(log.user).to be_present
      expect(log.salary_record).to be_present
    end

    it "nullifies salary_record_id when salary_record is deleted without destroying audit log" do
      record = log.salary_record
      record.destroy
      expect(log.reload.salary_record_id).to be_nil
    end
  end
end
