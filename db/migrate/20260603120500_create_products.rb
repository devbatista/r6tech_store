class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products, id: :uuid do |t|
      t.references :category, type: :uuid, foreign_key: true
      t.text :description
      t.string :name
      t.decimal :price
      t.timestamps
    end
  end
end
