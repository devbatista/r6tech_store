class ProductAiSuggestionSweepJob
  include Sidekiq::Job

  sidekiq_options queue: :default

  def perform
    products_missing_description.find_each do |product|
      queue_product(product)
    end

    products_missing_images.find_each do |product|
      queue_product(product)
    end
  end

  private

    def products_missing_description
      Product
        .where(description: [nil, ""])
        .where(ai_description_status: %w[idle failed])
    end

    def products_missing_images
      Product
        .left_outer_joins(:images_attachments)
        .where(active_storage_attachments: { id: nil })
        .where(ai_image_status: %w[idle failed])
    end

    def queue_product(product)
      updates = { ai_error: nil }
      updates[:ai_description_status] = "pending" if product.description.blank?
      updates[:ai_image_status] = "pending" unless product.images.attached?
      product.update!(updates)

      ProductAiSuggestionJob.perform_async(product.id)
    end
end
