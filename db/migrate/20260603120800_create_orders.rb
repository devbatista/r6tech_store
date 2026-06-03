class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :status
      t.decimal :total
      t.timestamps
    end
  end
end
