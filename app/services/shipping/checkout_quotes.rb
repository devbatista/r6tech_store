module Shipping
  class CheckoutQuotes
    def self.call(cart:, destination_postal_code:, setting: Setting.instance)
      new(cart: cart, destination_postal_code: destination_postal_code, setting: setting).call
    end

    def initialize(cart:, destination_postal_code:, setting:)
      @cart = cart
      @destination_postal_code = destination_postal_code
      @setting = setting
    end

    def call
      return fixed_quote unless melhor_envio_configured?

      Quote.call(cart: cart, destination_postal_code: destination_postal_code)
    end

    private

      attr_reader :cart, :destination_postal_code, :setting

      def melhor_envio_configured?
        token = Rails.application.credentials.dig(:melhor_envio, :token) || ENV["MELHOR_ENVIO_TOKEN"]
        token.present? && ENV["MELHOR_ENVIO_ORIGIN_POSTAL_CODE"].present?
      end

      def fixed_quote
        [{
          provider: "store",
          service_id: "fixed",
          service: I18n.t("storefront.shipping.fixed_service"),
          carrier: I18n.t("storefront.shipping.store_carrier"),
          price: BigDecimal(cart.shipping_cost(setting).to_s),
          delivery_days: nil
        }]
      end
  end
end
