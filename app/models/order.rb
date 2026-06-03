class Order < ApplicationRecord
  belongs_to :user
  belongs_to :shipping_address, class_name: "Address", optional: true
  has_many :order_items, dependent: :destroy

  SHIPPING_FIELDS = %i[recipient zip_code street number complement neighborhood city state country].freeze

  enum :status, {
    pending: "pending",
    paid: "paid",
    shipped: "shipped",
    delivered: "delivered",
    cancelled: "cancelled"
  }

  validates :status, presence: true
  validates :total, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Copia (congela) os dados do endereço para o pedido e guarda a referência.
  def assign_shipping_address(address)
    self.shipping_address = address
    SHIPPING_FIELDS.each { |field| public_send("shipping_#{field}=", address.public_send(field)) }
  end

  def shipping_address?
    shipping_street.present?
  end

  def shipping_address_line(separator = ", ")
    [shipping_street, shipping_number, shipping_complement, shipping_neighborhood,
     shipping_city, shipping_state, shipping_zip_code, shipping_country]
      .map { |part| part.to_s.strip.presence }
      .compact
      .join(separator)
  end
end
