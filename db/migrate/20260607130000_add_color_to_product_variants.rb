class AddColorToProductVariants < ActiveRecord::Migration[8.1]
  def change
    add_reference :product_variants, :color, type: :uuid, foreign_key: true, null: true

    remove_index :product_variants, column: [:product_id, :memory_id, :storage_id], unique: true
    add_index :product_variants, [:product_id, :color_id, :memory_id, :storage_id],
              unique: true, name: "index_product_variants_on_product_color_memory_storage"
  end
end
