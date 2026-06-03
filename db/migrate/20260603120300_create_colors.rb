class CreateColors < ActiveRecord::Migration[8.1]
  def change
    create_table :colors, id: :uuid do |t|
      t.string :hex, null: false
      t.string :name, null: false
    end
  end
end
