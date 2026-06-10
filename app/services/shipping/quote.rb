module Shipping
  class Quote
    def self.call(cart:, destination_postal_code:, provider: Providers::MelhorEnvio::QuoteCalculator.new)
      provider.call(cart: cart, destination_postal_code: destination_postal_code)
    end
  end
end
