class AddShippingQuoteToOrders < ActiveRecord::Migration[8.1]
  def change
    change_table :orders, bulk: true do |t|
      t.string :shipping_provider
      t.string :shipping_service_id
      t.string :shipping_service
      t.string :shipping_carrier
      t.decimal :shipping_cost, precision: 12, scale: 2, default: 0, null: false
      t.integer :shipping_delivery_days
    end
  end
end
