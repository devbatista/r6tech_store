class AddShippingDimensionsToProducts < ActiveRecord::Migration[8.1]
  def change
    change_table :products, bulk: true do |t|
      t.decimal :weight, precision: 8, scale: 3
      t.decimal :width, precision: 8, scale: 2
      t.decimal :height, precision: 8, scale: 2
      t.decimal :length, precision: 8, scale: 2
    end
  end
end
