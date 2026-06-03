class CreateAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :addresses, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.string :label
      t.string :recipient
      t.string :zip_code
      t.string :street
      t.string :number
      t.string :complement
      t.string :neighborhood
      t.string :city
      t.string :state
      t.string :country, default: "Brasil"
      t.boolean :default, null: false, default: false

      t.timestamps
    end
  end
end
