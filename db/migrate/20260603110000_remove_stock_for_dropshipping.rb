class RemoveStockForDropshipping < ActiveRecord::Migration[8.1]
  def change
    drop_table :product_stocks, if_exists: true do |t|
      t.uuid :product_id, null: false
      t.uuid :color_id
      t.uuid :storage_id
      t.integer :quantity, default: 0, null: false
      t.timestamps
    end

    remove_column :products, :stock, :integer, if_exists: true
  end
end
