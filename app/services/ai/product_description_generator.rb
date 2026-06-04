module Ai
  class ProductDescriptionGenerator
    def initialize(product:, provider:)
      @product = product
      @provider = provider
    end

    def call
      provider.generate_product_description(product_context)
    end

    private

      attr_reader :product, :provider

      def product_context
        {
          name: product.name,
          category: product.category&.name,
          price: product.price
        }
      end
  end
end
