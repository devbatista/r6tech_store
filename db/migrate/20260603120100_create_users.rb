class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users, id: :uuid do |t|
      t.date :birthdate
      t.string :email
      t.string :encrypted_password, default: "", null: false
      t.string :name
      t.string :password_digest
      t.string :phone
      t.datetime :remember_created_at
      t.datetime :reset_password_sent_at
      t.string :reset_password_token
      t.integer :role, default: 0, null: false
      t.timestamps

      t.index :email, unique: true
      t.index :reset_password_token, unique: true
    end
  end
end
