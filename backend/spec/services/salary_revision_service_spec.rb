require "rails_helper"

RSpec.describe SalaryRevisionService do
  let(:hr_user) { create(:user, role: "hr_manager") }
  let(:employee) { create(:employee) }

  let!(:initial_salary) do
    create(:salary_record,
           employee: employee,
           amount: 85_000,
           currency: "USD",
           effective_from: Date.new(2023, 1, 1),
           effective_to: nil)
  end

  describe "#call" do
    it "creates a new salary record and closes the previous record" do
      service = described_class.new(
        employee: employee,
        params: {
          amount: 100_000,
          currency: "USD",
          effective_from: "2024-01-01",
          change_reason: "annual_merit"
        },
        current_user: hr_user,
        client_info: { ip_address: "192.168.1.1", user_agent: "RSpec" }
      )

      new_record = service.call

      expect(new_record).to be_persisted
      expect(new_record.amount).to eq(100_000)
      expect(new_record.effective_from).to eq(Date.new(2024, 1, 1))
      expect(new_record.effective_to).to be_nil

      # Verify previous record is closed on the day prior to new revision
      initial_salary.reload
      expect(initial_salary.effective_to).to eq(Date.new(2023, 12, 31))

      # Verify audit log was created
      audit_log = SalaryAuditLog.last
      expect(audit_log.employee).to eq(employee)
      expect(audit_log.user).to eq(hr_user)
      expect(audit_log.action).to eq("update")
      expect(audit_log.previous_amount).to eq(85_000)
      expect(audit_log.new_amount).to eq(100_000)
      expect(audit_log.change_reason).to eq("annual_merit")
      expect(audit_log.ip_address).to eq("192.168.1.1")
    end

    it "raises RevisionError and rolls back changes if new date precedes active start date" do
      service = described_class.new(
        employee: employee,
        params: {
          amount: 95_000,
          currency: "USD",
          effective_from: "2022-06-01",
          change_reason: "retroactive_error"
        },
        current_user: hr_user
      )

      expect {
        service.call
      }.to raise_error(SalaryRevisionService::RevisionError, /must be strictly after/)

      # Verify initial salary remained untouched
      initial_salary.reload
      expect(initial_salary.effective_to).to be_nil
      expect(employee.salary_records.count).to eq(1)
    end

    it "raises RevisionError for non-positive salary amounts" do
      service = described_class.new(
        employee: employee,
        params: {
          amount: -500,
          currency: "USD",
          effective_from: "2024-01-01",
          change_reason: "invalid_amount"
        },
        current_user: hr_user
      )

      expect {
        service.call
      }.to raise_error(SalaryRevisionService::RevisionError, /greater than zero/)
    end
  end
end
