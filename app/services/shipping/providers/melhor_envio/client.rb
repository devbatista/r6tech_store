require "net/http"
require "uri"

module Shipping
  module Providers
    module MelhorEnvio
      class Client
        SANDBOX_URL = "https://sandbox.melhorenvio.com.br".freeze
        PRODUCTION_URL = "https://melhorenvio.com.br".freeze

        def initialize(
          token: Rails.application.credentials.dig(:melhor_envio, :token) || ENV["MELHOR_ENVIO_TOKEN"],
          base_url: ENV.fetch("MELHOR_ENVIO_BASE_URL", SANDBOX_URL),
          user_agent: ENV.fetch("MELHOR_ENVIO_USER_AGENT", "r6tech_store (contato@example.com)")
        )
          @token = token
          @base_url = base_url
          @user_agent = user_agent
        end

        def calculate(payload)
          post("/api/v2/me/shipment/calculate", payload)
        end

        private

          attr_reader :token, :base_url, :user_agent

          def post(path, payload)
            raise ConfigurationError, "MELHOR_ENVIO_TOKEN is missing" if token.blank?

            uri = URI.join("#{base_url}/", path.delete_prefix("/"))
            request = Net::HTTP::Post.new(uri)
            request["Accept"] = "application/json"
            request["Authorization"] = "Bearer #{token}"
            request["Content-Type"] = "application/json"
            request["User-Agent"] = user_agent
            request.body = payload.to_json

            response = Net::HTTP.start(
              uri.hostname,
              uri.port,
              use_ssl: uri.scheme == "https",
              open_timeout: 5,
              read_timeout: 15
            ) { |http| http.request(request) }

            body = JSON.parse(response.body)
            return body if response.is_a?(Net::HTTPSuccess)

            raise ProviderError.new(
              body["message"].presence || "Melhor Envio request failed",
              status: response.code.to_i,
              response_body: body
            )
          rescue JSON::ParserError
            raise ProviderError.new(
              "Melhor Envio returned an invalid response",
              status: response&.code&.to_i,
              response_body: response&.body
            )
          rescue Timeout::Error, SocketError, SystemCallError => error
            raise ProviderError, "Melhor Envio is unavailable: #{error.message}"
          end
      end
    end
  end
end
