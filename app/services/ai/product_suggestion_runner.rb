module Ai
  class ProductSuggestionRunner
    def initialize(product:, provider: Providers::OpenAi.new, force: false)
      @product = product
      @provider = provider
      @force = force
    end

    def call
      reset_suggestions

      generate_description if generate_description?
      generate_image if generate_image?

      product.update!(ai_error: nil)
    rescue StandardError => error
      product.update!(
        ai_description_status: failed_status(product.ai_description_status),
        ai_image_status: failed_status(product.ai_image_status),
        ai_error: error.message.truncate(500)
      )
    end

    private

      attr_reader :product, :provider

      def reset_suggestions
        updates = { ai_error: nil }
        updates[:ai_description_status] = "pending" if generate_description?
        updates[:ai_image_status] = "pending" if generate_image?
        product.ai_generated_images.purge if updates[:ai_image_status] == "pending"
        product.update!(updates)
      end

      def generate_description
        description = ProductDescriptionGenerator.new(product: product, provider: provider).call
        product.update!(ai_description: description, ai_description_status: "ready")
      end

      def generate_image
        image = ProductImageGenerator.new(product: product, provider: provider).call
        product.ai_generated_images.attach(
          io: image.fetch(:io),
          filename: image.fetch(:filename),
          content_type: image.fetch(:content_type)
        )
        product.update!(ai_image_status: "ready")
      ensure
        image&.fetch(:io)&.close
      end

      def failed_status(status)
        status == "pending" ? "failed" : status
      end

      def generate_description?
        force || product.description.blank?
      end

      def generate_image?
        force || !product.images.attached?
      end

      def force
        @force
      end
  end
end
