class AddShippingAddressToOrders < ActiveRecord::Migration[8.1]
  def change
    # Endereço de entrega "congelado" no momento da compra. Mantemos uma
    # referência opcional ao Address de origem (nula se ele for removido).
    add_reference :orders, :shipping_address, type: :uuid, foreign_key: { to_table: :addresses, on_delete: :nullify }, null: true

    add_column :orders, :shipping_recipient, :string
    add_column :orders, :shipping_zip_code, :string
    add_column :orders, :shipping_street, :string
    add_column :orders, :shipping_number, :string
    add_column :orders, :shipping_complement, :string
    add_column :orders, :shipping_neighborhood, :string
    add_column :orders, :shipping_city, :string
    add_column :orders, :shipping_state, :string
    add_column :orders, :shipping_country, :string
  end
end
