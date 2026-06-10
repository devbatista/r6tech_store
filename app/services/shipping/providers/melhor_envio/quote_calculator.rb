module Shipping
  module Providers
    module MelhorEnvio
      class QuoteCalculator
        def initialize(client: Client.new, origin_postal_code: ENV["MELHOR_ENVIO_ORIGIN_POSTAL_CODE"])
          @client = client
          @origin_postal_code = sanitize_postal_code(origin_postal_code)
        end

        def call(cart:, destination_postal_code:)
          validate_origin!
          validate_cart!(cart)
          destination = sanitize_postal_code(destination_postal_code)
          validate_destination!(destination)

          response = client.calculate(
            from: { postal_code: origin_postal_code },
            to: { postal_code: destination },
            products: cart.cart_items.includes(:product, :storage, :memory, :color).map { |item| product_payload(item) }
          )

          normalize_quotes(response)
        end

        private

          attr_reader :client, :origin_postal_code

          def sanitize_postal_code(value)
            value.to_s.gsub(/\D/, "")
          end

          def validate_origin!
            return if origin_postal_code.match?(/\A\d{8}\z/)

            raise ConfigurationError, "MELHOR_ENVIO_ORIGIN_POSTAL_CODE must contain 8 digits"
          end

          def validate_destination!(destination)
            return if destination.match?(/\A\d{8}\z/)

            raise InvalidPackageError, "Destination postal code must contain 8 digits"
          end

          def validate_cart!(cart)
            raise InvalidPackageError, "Cart is empty" if cart.cart_items.empty?

            incomplete = cart.cart_items.filter_map do |item|
              item.product.name unless item.product.shipping_dimensions_complete?
            end
            return if incomplete.empty?

            raise InvalidPackageError, "Missing shipping dimensions for: #{incomplete.uniq.join(', ')}"
          end

          def product_payload(item)
            {
              id: item.product_id,
              width: item.product.width.to_f,
              height: item.product.height.to_f,
              length: item.product.length.to_f,
              weight: item.product.weight.to_f,
              insurance_value: item.unit_price.to_f,
              quantity: item.quantity
            }
          end

          def normalize_quotes(response)
            Array(response).filter_map do |quote|
              next if quote["error"].present?

              {
                provider: "melhor_envio",
                service_id: quote["id"],
                service: quote["name"],
                carrier: quote.dig("company", "name"),
                price: BigDecimal(quote["custom_price"].presence || quote["price"].to_s),
                delivery_days: (quote["custom_delivery_time"].presence || quote["delivery_time"]).to_i,
                raw: quote
              }
            end
          end
      end
    end
  end
end
