require "rails_helper"
require "securerandom"

RSpec.describe Product, type: :model do
  it { should have_many(:cart_items) }
  it { should have_many(:order_items) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:price) }
  it { should validate_numericality_of(:price).is_greater_than_or_equal_to(0) }

  it "allows products without a description" do
    category = Category.create!(name: "Books #{SecureRandom.uuid}")
    product = Product.new(name: "Ruby Book", price: 50, category: category, description: nil)

    expect(product).to be_valid
  end

  it "has storefront and AI-generated image attachments" do
    expect(Product.reflect_on_attachment(:images)).to be_present
    expect(Product.reflect_on_attachment(:ai_generated_images)).to be_present
  end

  describe "category association" do
    it "belongs to a category" do
      category = Category.create!(name: "Books #{SecureRandom.uuid}")
      product = Product.create!(name: "Ruby Book", price: 50, category: category)
      expect(product.category).to(eq(category))
    end

    it "is invalid without a category" do
      product = Product.new(name: "No Category", price: 10, category: nil)
      expect(product.valid?).to(be_falsey)
      expect(product.errors[:category]).to(include(I18n.t("errors.messages.required")))
    end
  end
end
