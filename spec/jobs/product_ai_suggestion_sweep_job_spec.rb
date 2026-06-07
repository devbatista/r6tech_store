require "rails_helper"
require "securerandom"
require "sidekiq/testing"

RSpec.describe ProductAiSuggestionSweepJob, type: :job do
  around do |example|
    Sidekiq::Testing.fake! do
      Sidekiq::Worker.clear_all

      example.run
    ensure
      Sidekiq::Worker.clear_all
    end
  end

  describe "#perform" do
    before do
      Product.update_all(
        description: "Existing description",
        ai_description_status: "approved",
        ai_image_status: "approved"
      )
    end

    it "queues products missing AI suggestions" do
      category = Category.create!(name: "Phones #{SecureRandom.uuid}")
      product = Product.create!(name: "iPhone 15", price: 4999.90, category: category)

      expect {
        described_class.new.perform
      }.to change(ProductAiSuggestionJob.jobs, :size).by(1)

      product.reload
      expect(ProductAiSuggestionJob.jobs.last["args"]).to eq([product.id])
      expect(product.ai_description_status).to eq("pending")
      expect(product.ai_image_status).to eq("pending")
    end

    it "does not queue products already pending" do
      category = Category.create!(name: "Phones #{SecureRandom.uuid}")
      Product.create!(
        name: "iPhone 15",
        price: 4999.90,
        category: category,
        ai_description_status: "pending",
        ai_image_status: "pending"
      )

      expect {
        described_class.new.perform
      }.not_to change(ProductAiSuggestionJob.jobs, :size)
    end

    it "does not automatically retry failed products" do
      category = Category.create!(name: "Phones #{SecureRandom.uuid}")
      Product.create!(
        name: "iPhone 15",
        price: 4999.90,
        category: category,
        ai_description_status: "failed",
        ai_image_status: "failed"
      )

      expect {
        described_class.new.perform
      }.not_to change(ProductAiSuggestionJob.jobs, :size)
    end
  end
end
