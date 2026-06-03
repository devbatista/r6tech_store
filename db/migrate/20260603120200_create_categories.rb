class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories, id: :uuid do |t|
      t.string :name
      t.uuid :parent_id
      t.timestamps

      t.index :parent_id
    end

    add_foreign_key :categories, :categories, column: :parent_id
  end
end
