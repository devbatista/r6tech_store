class CreateStorages < ActiveRecord::Migration[8.1]
  def change
    create_table :storages, id: :uuid do |t|
      t.string :value
    end
  end
end
