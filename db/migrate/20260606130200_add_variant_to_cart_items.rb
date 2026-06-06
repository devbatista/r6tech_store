class AddVariantToCartItems < ActiveRecord::Migration[8.1]
  def change
    add_reference :cart_items, :color, type: :uuid, foreign_key: true, null: true
    add_reference :cart_items, :storage, type: :uuid, foreign_key: true, null: true
  end
end
