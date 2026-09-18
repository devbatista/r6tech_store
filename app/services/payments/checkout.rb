module Payments
  # Cria (ou reaproveita) a preference do Checkout Pro para um pagamento e devolve
  # a URL para onde o cliente deve ser redirecionado.
  class Checkout
    PROVIDER = "mercado_pago".freeze

    def self.call(payment:, **options)
      new(payment: payment, **options).call
    end

    def initialize(payment:, client: Providers::MercadoPago::Client.new, setting: Setting.instance)
      @payment = payment
      @client = client
      @setting = setting
    end

    def call
      raise Error, "payment is not payable" unless payment.payable?
      return payment.checkout_url if payment.checkout_url.present?

      payload = Providers::MercadoPago::Preference.new(payment: payment, setting: setting).to_h
      preference = client.create_preference(payload, idempotency_key: payment.id)

      payment.update!(
        provider: PROVIDER,
        metadata: payment.metadata.merge(
          "preference_id" => preference["id"],
          "init_point" => preference["init_point"]
        )
      )

      payment.checkout_url
    end

    private

      attr_reader :payment, :client, :setting
  end
end
