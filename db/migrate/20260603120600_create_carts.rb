class CreateCarts < ActiveRecord::Migration[8.1]
  def change
    create_table :carts, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.integer :status
      t.timestamps
    end
  end
end
