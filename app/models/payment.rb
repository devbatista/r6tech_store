class Payment < ApplicationRecord
  belongs_to :order

  enum :payment_method, {
    pix: "pix",
    credit_card: "credit_card",
    boleto: "boleto"
  }

  enum :status, {
    awaiting_payment: "awaiting_payment",
    processing: "processing",
    paid: "paid",
    failed: "failed",
    cancelled: "cancelled",
    refunded: "refunded"
  }

  validates :payment_method, :status, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Ainda pode ser pago pelo cliente (inclui nova tentativa depois de uma recusa).
  def payable?
    awaiting_payment? || failed?
  end

  # URL do Checkout Pro guardada quando a preference foi criada.
  def checkout_url
    metadata["init_point"].presence
  end

  def provider_status
    metadata["provider_status"].presence
  end
end
