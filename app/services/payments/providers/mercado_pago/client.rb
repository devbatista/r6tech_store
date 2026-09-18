require "net/http"
require "uri"

module Payments
  module Providers
    module MercadoPago
      # Cliente HTTP mínimo da API do Mercado Pago. O ambiente de teste é definido pelo
      # tipo do access token (TEST-... ou APP_USR-...), não pela URL.
      class Client
        BASE_URL = "https://api.mercadopago.com".freeze

        def initialize(access_token: Client.access_token)
          @access_token = access_token
        end

        def self.access_token
          Rails.application.credentials.dig(:mercado_pago, :access_token) || ENV["MERCADO_PAGO_ACCESS_TOKEN"]
        end

        def self.webhook_secret
          Rails.application.credentials.dig(:mercado_pago, :webhook_secret) || ENV["MERCADO_PAGO_WEBHOOK_SECRET"]
        end

        # https://www.mercadopago.com.br/developers/pt/reference/preferences/_checkout_preferences/post
        def create_preference(payload, idempotency_key: nil)
          request(Net::HTTP::Post, "/checkout/preferences", payload, idempotency_key: idempotency_key)
        end

        # https://www.mercadopago.com.br/developers/pt/reference/payments/_payments_id/get
        def fetch_payment(payment_id)
          request(Net::HTTP::Get, "/v1/payments/#{payment_id}")
        end

        private

          attr_reader :access_token

          def request(request_class, path, payload = nil, idempotency_key: nil)
            raise ConfigurationError, "MERCADO_PAGO_ACCESS_TOKEN is missing" if access_token.blank?

            uri = URI.join(BASE_URL, path)
            request = request_class.new(uri)
            request["Accept"] = "application/json"
            request["Authorization"] = "Bearer #{access_token}"
            request["Content-Type"] = "application/json"
            request["X-Idempotency-Key"] = idempotency_key if idempotency_key
            request.body = payload.to_json if payload

            response = Net::HTTP.start(
              uri.hostname,
              uri.port,
              use_ssl: true,
              open_timeout: 5,
              read_timeout: 15
            ) { |http| http.request(request) }

            body = JSON.parse(response.body)
            return body if response.is_a?(Net::HTTPSuccess)

            raise ProviderError.new(
              body["message"].presence || "Mercado Pago request failed",
              status: response.code.to_i,
              response_body: body
            )
          rescue JSON::ParserError
            raise ProviderError.new(
              "Mercado Pago returned an invalid response",
              status: response&.code&.to_i,
              response_body: response&.body
            )
          rescue Timeout::Error, SocketError, SystemCallError => error
            raise ProviderError, "Mercado Pago is unavailable: #{error.message}"
          end
      end
    end
  end
end
