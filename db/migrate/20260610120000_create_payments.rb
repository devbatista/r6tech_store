class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments, id: :uuid do |t|
      t.references :order, null: false, type: :uuid, foreign_key: true, index: { unique: true }
      t.string :payment_method, null: false
      t.string :status, null: false, default: "awaiting_payment"
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :provider
      t.string :external_reference
      t.jsonb :metadata, null: false, default: {}
      t.timestamps

      t.index :external_reference
      t.index :status
    end
  end
end
