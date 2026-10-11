class SalaryRevisionService
  class RevisionError < StandardError; end

  attr_reader :employee, :params, :current_user, :client_info

  def initialize(employee:, params:, current_user:, client_info: {})
    @employee = employee
    @params = params
    @current_user = current_user
    @client_info = client_info
  end

  def call
    ActiveRecord::Base.transaction do
      effective_from = parse_date(params[:effective_from])
      amount = BigDecimal(params[:amount].to_s)
      currency = params[:currency].to_s.upcase.strip
      change_reason = params[:change_reason].to_s.strip

      raise RevisionError, "Amount must be greater than zero" if amount <= 0
      raise RevisionError, "Currency must be a 3-letter ISO code" unless currency.match?(/\A[A-Z]{3}\z/)
      raise RevisionError, "Change reason is required" if change_reason.blank?
      raise RevisionError, "Effective from date is required" if effective_from.blank?

      # Find currently active open-ended record if exists
      active_record = employee.salary_records.where(effective_to: nil).order(effective_from: :desc).first

      if active_record.present?
        if effective_from <= active_record.effective_from
          raise RevisionError, "New effective date (#{effective_from}) must be strictly after the existing record's start date (#{active_record.effective_from})"
        end

        # Close the preceding salary record on the day before the new revision
        active_record.update!(effective_to: effective_from - 1.day)
      end

      # Create the new effective-dated salary record
      new_salary_record = employee.salary_records.create!(
        amount: amount,
        currency: currency,
        effective_from: effective_from,
        effective_to: nil,
        pay_frequency: params[:pay_frequency].presence || "annual",
        change_reason: change_reason
      )

      # Create transactional audit log entry
      SalaryAuditLog.create!(
        salary_record: new_salary_record,
        employee: employee,
        user: current_user,
        action: active_record ? "update" : "create",
        previous_amount: active_record&.amount,
        new_amount: amount,
        previous_currency: active_record&.currency,
        new_currency: currency,
        previous_effective_from: active_record&.effective_from,
        new_effective_from: effective_from,
        previous_effective_to: active_record&.effective_to,
        new_effective_to: nil,
        change_reason: change_reason,
        ip_address: client_info[:ip_address],
        user_agent: client_info[:user_agent]
      )

      new_salary_record
    end
  rescue ActiveRecord::RecordInvalid => e
    raise RevisionError, e.record.errors.full_messages.join(", ")
  end

  private

  def parse_date(val)
    return val if val.is_a?(Date)
    Date.parse(val.to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
