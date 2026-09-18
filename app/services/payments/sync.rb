module Payments
  # Busca um pagamento na API do Mercado Pago e reflete o resultado em Payment e Order.
  # É chamado pelo webhook e pela URL de retorno do checkout; pode rodar mais de uma vez
  # para o mesmo pagamento sem efeito colateral.
  class Sync
    # https://www.mercadopago.com.br/developers/pt/docs/checkout-pro/additional-content/payment-status
    STATUS_MAP = {
      "approved" => "paid",
      "authorized" => "processing",
      "in_process" => "processing",
      "in_mediation" => "processing",
      "pending" => "processing",
      "rejected" => "failed",
      "cancelled" => "cancelled",
      "refunded" => "refunded",
      "charged_back" => "refunded"
    }.freeze

    def self.call(provider_payment_id:, **options)
      new(provider_payment_id: provider_payment_id, **options).call
    end

    def initialize(provider_payment_id:, client: Providers::MercadoPago::Client.new)
      @provider_payment_id = provider_payment_id
      @client = client
    end

    # Devolve o Payment atualizado, ou nil se a notificação não corresponder a um pedido da loja.
    def call
      data = client.fetch_payment(provider_payment_id)
      payment = find_payment(data)
      return unless payment

      status = STATUS_MAP.fetch(data["status"], "processing")

      Payment.transaction do
        payment.update!(
          provider: Checkout::PROVIDER,
          external_reference: data["id"].to_s,
          status: status,
          metadata: payment.metadata.merge(
            "provider_status" => data["status"],
            "provider_status_detail" => data["status_detail"],
            "payment_type" => data["payment_type_id"],
            "payment_method_id" => data["payment_method_id"],
            "synced_at" => Time.current.iso8601
          )
        )
        update_order(payment.order, status)
      end

      payment
    end

    private

      attr_reader :provider_payment_id, :client

      # external_reference da preference é o id do pedido; o metadata leva o id do Payment.
      def find_payment(data)
        payment_id = data.dig("metadata", "payment_id")
        order_id = data["external_reference"]

        Payment.find_by(id: payment_id) || Payment.find_by(order_id: order_id)
      end

      def update_order(order, payment_status)
        target = case payment_status
                 when "paid" then "paid"
                 when "cancelled", "refunded" then "cancelled"
                 end
        return unless target
        return if order.status == target
        return unless order.can_transition_to?(target)

        order.update!(status: target)
      end
  end
end
