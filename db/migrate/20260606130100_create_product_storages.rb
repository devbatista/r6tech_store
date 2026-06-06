class CreateProductStorages < ActiveRecord::Migration[8.1]
  def change
    create_table :product_storages, id: :uuid do |t|
      t.references :product, null: false, type: :uuid, foreign_key: true
      t.references :storage, null: false, type: :uuid, foreign_key: true
      t.decimal :price, precision: 10, scale: 2, null: false
      t.timestamps
    end

    add_index :product_storages, [:product_id, :storage_id], unique: true
  end
end
