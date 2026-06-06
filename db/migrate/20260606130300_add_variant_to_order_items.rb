class AddVariantToOrderItems < ActiveRecord::Migration[8.1]
  def change
    add_reference :order_items, :color, type: :uuid, foreign_key: true, null: true
    add_reference :order_items, :storage, type: :uuid, foreign_key: true, null: true
  end
end
