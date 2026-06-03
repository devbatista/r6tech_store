class CreateSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :settings, id: :uuid do |t|
      # Store
      t.string :store_name
      t.string :contact_email
      t.string :contact_phone
      t.string :instagram_url
      t.string :facebook_url
      t.string :whatsapp
      t.string :currency, default: "BRL"
      t.string :timezone, default: "Brasilia"

      # Shipping & Orders
      t.decimal :shipping_fee, precision: 10, scale: 2, default: 0
      t.decimal :free_shipping_threshold, precision: 10, scale: 2
      t.decimal :tax_rate, precision: 5, scale: 2, default: 0
      t.string :default_order_status, default: "pending"

      # Notifications
      t.string :notification_sender
      t.boolean :notify_on_paid, null: false, default: true
      t.boolean :notify_on_shipped, null: false, default: true
      t.boolean :notify_on_delivered, null: false, default: false

      # Payments
      t.boolean :pay_pix, null: false, default: true
      t.boolean :pay_credit_card, null: false, default: true
      t.boolean :pay_boleto, null: false, default: false

      # Appearance
      t.boolean :default_dark_mode, null: false, default: false

      t.timestamps
    end
  end
end
