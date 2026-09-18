module Webhooks
  # Recebe as notificações do Mercado Pago. Só o tipo "payment" interessa; o resto
  # é aceito com 200 para o Mercado Pago não ficar reenviando.
  # https://www.mercadopago.com.br/developers/pt/docs/your-integrations/notifications/webhooks
  class MercadoPagoController < ActionController::API
    def create
      return head :unauthorized unless valid_signature?

      if payment_notification?
        Payments::SyncJob.perform_later(data_id.to_s)
      end

      head :ok
    end

    private

      # O id vem na query (data.id) nas notificações novas e em `id` nas antigas (topic).
      def data_id
        request.query_parameters["data.id"].presence ||
          params.dig(:data, :id).presence ||
          request.query_parameters["id"].presence
      end

      def payment_notification?
        type = params[:type].presence || request.query_parameters["topic"].presence
        type == "payment" && data_id.present?
      end

      def valid_signature?
        Payments::Providers::MercadoPago::WebhookSignature.new(
          signature_header: request.headers["x-signature"],
          request_id: request.headers["x-request-id"],
          data_id: request.query_parameters["data.id"]
        ).valid?
      end
  end
end
