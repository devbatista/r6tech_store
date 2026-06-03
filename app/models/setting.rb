class Setting < ApplicationRecord
  has_one_attached :logo

  CURRENCIES = %w[BRL USD EUR].freeze
  TIMEZONES = ["Brasilia", "Fernando de Noronha", "Manaus", "Rio Branco"].freeze
  ORDER_STATUSES = Order.statuses.keys.freeze

  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :currency, inclusion: { in: CURRENCIES }, allow_blank: true
  validates :shipping_fee, :tax_rate, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :free_shipping_threshold, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :default_order_status, inclusion: { in: ORDER_STATUSES }, allow_blank: true

  # Configuração da loja é um registro único (singleton).
  def self.instance
    first_or_create!
  end
end
