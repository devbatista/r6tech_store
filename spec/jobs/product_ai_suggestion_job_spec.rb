require "rails_helper"
require "securerandom"

RSpec.describe ProductAiSuggestionJob, type: :job do
  describe "#perform" do
    it "runs product AI suggestions" do
      category = Category.create!(name: "Phones #{SecureRandom.uuid}")
      product = Product.create!(name: "iPhone 15", price: 4999.90, category: category)
      runner = instance_double(Ai::ProductSuggestionRunner, call: true)

      allow(Ai::ProductSuggestionRunner).to receive(:new)
        .with(product: product, force: false)
        .and_return(runner)

      described_class.new.perform(product.id)

      expect(runner).to have_received(:call)
    end
  end
end
