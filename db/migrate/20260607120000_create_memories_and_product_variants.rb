class CreateMemoriesAndProductVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :memories, id: :uuid do |t|
      t.string :value, null: false

      t.timestamps
    end
    add_index :memories, :value, unique: true

    create_table :product_variants, id: :uuid do |t|
      t.references :product, null: false, type: :uuid, foreign_key: true
      t.references :memory, null: false, type: :uuid, foreign_key: true
      t.references :storage, null: false, type: :uuid, foreign_key: true
      t.decimal :price, precision: 10, scale: 2, null: false

      t.timestamps
    end
    add_index :product_variants, [:product_id, :memory_id, :storage_id], unique: true

    add_reference :cart_items, :memory, type: :uuid, foreign_key: true
    add_reference :order_items, :memory, type: :uuid, foreign_key: true
  end
end
