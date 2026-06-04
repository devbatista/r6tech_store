class ProductAiSuggestionJob
  include Sidekiq::Job

  sidekiq_options queue: :default

  def perform(product_id, force = false)
    product = Product.find(product_id)
    Ai::ProductSuggestionRunner.new(product: product, force: force).call
  end
end
