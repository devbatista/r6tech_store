class Order < ApplicationRecord
  belongs_to :user
  belongs_to :shipping_address, class_name: "Address", optional: true
  has_many :order_items, dependent: :destroy
  has_one :payment, dependent: :destroy

  SHIPPING_FIELDS = %i[recipient zip_code street number complement neighborhood city state country].freeze

  # Transições de status permitidas a partir de cada estado.
  STATUS_TRANSITIONS = {
    "pending"   => %w[paid cancelled],
    "paid"      => %w[shipped cancelled],
    "shipped"   => %w[delivered],
    "delivered" => [],
    "cancelled" => []
  }.freeze

  enum :status, {
    pending: "pending",
    paid: "paid",
    shipped: "shipped",
    delivered: "delivered",
    cancelled: "cancelled"
  }

  validates :status, presence: true
  validates :total, presence: true, numericality: { greater_than_or_equal_to: 0 }
  after_update :sync_payment_status, if: :saved_change_to_status?

  def self.create_from_cart!(user:, cart:, setting: Setting.instance, shipping_address: nil, shipping_quote: nil)
    quote = shipping_quote || {
      provider: "store",
      service_id: "fixed",
      service: "Fixed shipping",
      price: cart.shipping_cost(setting),
      delivery_days: nil
    }

    order = new(
      user: user,
      status: :pending,
      total: cart.total_value + quote.fetch(:price),
      shipping_provider: quote[:provider],
      shipping_service_id: quote[:service_id],
      shipping_service: quote[:service],
      shipping_carrier: quote[:carrier],
      shipping_cost: quote.fetch(:price),
      shipping_delivery_days: quote[:delivery_days]
    )
    order.assign_shipping_address(shipping_address) if shipping_address
    order.save!

    order.tap do
      cart.cart_items.each do |item|
        order.order_items.create!(
          product: item.product,
          quantity: item.quantity,
          price: item.unit_price,
          color: item.color,
          storage: item.storage,
          memory: item.memory
        )
      end

      cart.update!(status: :ordered)
    end
  end

  # Status para os quais este pedido pode mudar a partir do estado atual.
  def available_status_transitions
    STATUS_TRANSITIONS.fetch(status, [])
  end

  def can_transition_to?(new_status)
    available_status_transitions.include?(new_status.to_s)
  end

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

  private

    def sync_payment_status
      return unless payment

      payment.paid! if paid? && !payment.paid?
      payment.cancelled! if cancelled? && !payment.cancelled?
    end
end
