require "rails_helper"
require "securerandom"

RSpec.describe Ai::ProductSuggestionRunner do
  include ActiveJob::TestHelper

  class FakeAiProvider
    def initialize(fail: false)
      @fail = fail
    end

    def generate_product_description(_context)
      raise "Provider unavailable" if @fail

      "Descricao gerada para a loja."
    end

    def generate_product_image(_context)
      raise "Provider unavailable" if @fail

      file = Tempfile.new(["generated", ".png"], binmode: true)
      file.write("fake image")
      file.rewind

      {
        io: file,
        filename: "generated.png",
        content_type: "image/png"
      }
    end
  end

  around do |example|
    original_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
    clear_performed_jobs

    example.run
  ensure
    clear_enqueued_jobs
    clear_performed_jobs
    ActiveJob::Base.queue_adapter = original_adapter
  end

  describe "#call" do
    it "stores generated suggestions and marks them as ready" do
      category = Category.create!(name: "Phones #{SecureRandom.uuid}")
      product = Product.create!(name: "iPhone 15", price: 4999.90, category: category)

      described_class.new(product: product, provider: FakeAiProvider.new).call

      product.reload
      expect(product.ai_description).to eq("Descricao gerada para a loja.")
      expect(product.ai_description_status).to eq("ready")
      expect(product.ai_image_status).to eq("ready")
      expect(product.ai_generated_images).to be_attached
      expect(product.ai_error).to be_nil
    end

    it "marks pending suggestions as failed when the provider fails" do
      category = Category.create!(name: "Phones #{SecureRandom.uuid}")
      product = Product.create!(name: "iPhone 15", price: 4999.90, category: category)

      described_class.new(product: product, provider: FakeAiProvider.new(fail: true)).call

      product.reload
      expect(product.ai_description_status).to eq("failed")
      expect(product.ai_image_status).to eq("failed")
      expect(product.ai_error).to include("Provider unavailable")
    end
  end
end
