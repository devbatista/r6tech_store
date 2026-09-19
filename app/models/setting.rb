class Setting < ApplicationRecord
  has_one_attached :logo

  FIXED_CURRENCY = "BRL".freeze
  DEFAULT_SENDER = "no-reply@r6tech.store".freeze
  DEFAULT_STORE_NAME = "R6tech Store".freeze
  TIMEZONES = ["Brasilia", "Fernando de Noronha", "Manaus", "Rio Branco"].freeze

  before_validation :force_brazilian_real

  validates :contact_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :shipping_fee, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :free_shipping_threshold, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :notification_sender, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  def display_name
    store_name.presence || DEFAULT_STORE_NAME
  end

  # Remetente dos e-mails transacionais (pedidos, Devise), no formato "Loja <email>".
  def sender_email
    notification_sender.presence || DEFAULT_SENDER
  end

  def sender_address
    ActionMailer::Base.email_address_with_name(sender_email, display_name)
  end

  # Flags de notificação por status do pedido; `pending` (confirmação) é sempre enviado.
  def notify_on?(status)
    case status.to_s
    when "pending" then true
    when "paid" then notify_on_paid
    when "shipped" then notify_on_shipped
    when "delivered" then notify_on_delivered
    else false
    end
  end

  # Configuração da loja é um registro único (singleton).
  def self.instance
    first_or_create!
  end

  private

    def force_brazilian_real
      self.currency = FIXED_CURRENCY
    end
end
