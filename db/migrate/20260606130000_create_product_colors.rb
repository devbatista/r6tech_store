class CreateProductColors < ActiveRecord::Migration[8.1]
  def change
    create_table :product_colors, id: :uuid do |t|
      t.references :product, null: false, type: :uuid, foreign_key: true
      t.references :color, null: false, type: :uuid, foreign_key: true
      t.timestamps
    end

    add_index :product_colors, [:product_id, :color_id], unique: true
  end
end
