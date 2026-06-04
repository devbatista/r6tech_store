require "base64"
require "net/http"
require "tempfile"
require "uri"

module Ai
  module Providers
    class OpenAi < Base
      API_URL = "https://api.openai.com/v1/responses".freeze
      TEXT_MODEL = ENV.fetch("OPENAI_TEXT_MODEL", "gpt-4.1-mini")
      IMAGE_RESPONSE_MODEL = ENV.fetch("OPENAI_IMAGE_RESPONSE_MODEL", TEXT_MODEL)

      def initialize(api_key: Rails.application.credentials.dig(:openai, :api_key) || ENV["OPENAI_API_KEY"])
        @api_key = api_key
      end

      def generate_product_description(context)
        response = post_json(
          model: TEXT_MODEL,
          input: description_prompt(context)
        )

        extract_text(response).presence || raise("OpenAI did not return a product description")
      end

      def generate_product_image(context)
        response = post_json(
          model: IMAGE_RESPONSE_MODEL,
          input: image_prompt(context),
          tools: [{ type: "image_generation" }],
          tool_choice: { type: "image_generation" }
        )

        image_base64 = extract_image_base64(response)
        raise "OpenAI did not return a product image" if image_base64.blank?

        file = Tempfile.new(["product-ai-image", ".png"], binmode: true)
        file.write(Base64.decode64(image_base64))
        file.rewind

        {
          io: file,
          filename: "ai-product-image-#{Time.current.to_i}.png",
          content_type: "image/png"
        }
      end

      private

        attr_reader :api_key

        def post_json(payload)
          raise "OPENAI_API_KEY is missing" if api_key.blank?

          uri = URI(API_URL)
          request = Net::HTTP::Post.new(uri)
          request["Authorization"] = "Bearer #{api_key}"
          request["Content-Type"] = "application/json"
          request.body = payload.to_json

          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
            http.request(request)
          end

          body = JSON.parse(response.body)
          raise body.dig("error", "message").presence || "OpenAI request failed" unless response.is_a?(Net::HTTPSuccess)

          body
        end

        def description_prompt(context)
          <<~PROMPT
            Crie uma descrição de produto em português do Brasil, com tom comercial claro e confiável.
            Use de 2 a 4 parágrafos curtos, sem inventar especificações técnicas ausentes.

            Produto: #{context[:name]}
            Categoria: #{context[:category]}
            Preço: #{context[:price]}
          PROMPT
        end

        def image_prompt(context)
          <<~PROMPT
            Gere uma foto de produto para e-commerce, em fundo neutro claro, com iluminação profissional.
            O produto deve parecer realista e centralizado, sem texto, logotipos inventados ou marcas d'água.

            Produto: #{context[:name]}
            Categoria: #{context[:category]}
          PROMPT
        end

        def extract_text(response)
          response["output_text"] ||
            response.fetch("output", []).filter_map { |item|
              item.fetch("content", []).filter_map { |content| content["text"] }.join
            }.join
        end

        def extract_image_base64(response)
          response.fetch("output", []).each do |item|
            item.fetch("content", []).each do |content|
              return content["result"] if content["type"] == "image_generation_call" && content["result"].present?
            end

            return item["result"] if item["type"] == "image_generation_call" && item["result"].present?
          end

          nil
        end
    end
  end
end
