require "openssl"

module Payments
  module Providers
    module MercadoPago
      # Valida o header x-signature das notificações de webhook.
      # https://www.mercadopago.com.br/developers/pt/docs/your-integrations/notifications/webhooks#validaodeorigemdanotificao
      class WebhookSignature
        def initialize(signature_header:, request_id:, data_id:, secret: Client.webhook_secret)
          @signature_header = signature_header.to_s
          @request_id = request_id
          @data_id = data_id
          @secret = secret
        end

        def valid?
          return false if secret.blank? || timestamp.blank? || signature.blank?

          expected = OpenSSL::HMAC.hexdigest("SHA256", secret, manifest)
          ActiveSupport::SecurityUtils.secure_compare(expected, signature)
        end

        private

          attr_reader :signature_header, :request_id, :data_id, :secret

          def parts
            @parts ||= signature_header.split(",").to_h do |pair|
              key, value = pair.split("=", 2)
              [key.to_s.strip, value.to_s.strip]
            end
          end

          def timestamp
            parts["ts"]
          end

          def signature
            parts["v1"]
          end

          # Formato exigido: "id:<data.id>;request-id:<x-request-id>;ts:<ts>;", omitindo
          # as partes ausentes. IDs alfanuméricos devem estar em minúsculas.
          def manifest
            manifest_parts = []
            manifest_parts << "id:#{normalized_data_id}" if data_id.present?
            manifest_parts << "request-id:#{request_id}" if request_id.present?
            manifest_parts << "ts:#{timestamp}" if timestamp.present?
            manifest_parts.map { |part| "#{part};" }.join
          end

          def normalized_data_id
            id = data_id.to_s
            id.match?(/\A\d+\z/) ? id : id.downcase
          end
      end
    end
  end
end
