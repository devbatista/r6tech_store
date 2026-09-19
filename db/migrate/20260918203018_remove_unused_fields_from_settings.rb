# Campos editáveis no admin mas nunca lidos pela aplicação (checklist, item 6).
class RemoveUnusedFieldsFromSettings < ActiveRecord::Migration[8.1]
  def change
    remove_column :settings, :tax_rate, :decimal, precision: 5, scale: 2, default: "0.0"
    remove_column :settings, :default_order_status, :string, default: "pending"
  end
end
