class AddEffectiveToIndexToSalaryRecords < ActiveRecord::Migration[8.1]
  def change
    add_index :salary_records, :effective_to, name: "idx_sal_effective_to"
    add_index :salary_records, [ :effective_to, :currency, :amount ], name: "idx_sal_active_currency_amount"
  end
end
