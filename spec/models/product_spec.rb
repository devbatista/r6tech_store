require "rails_helper"
require "securerandom"

RSpec.describe Product, type: :model do
  it { should have_many(:cart_items) }
  it { should have_many(:order_items) }

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:price) }
  it { should validate_numericality_of(:price).is_greater_than_or_equal_to(0) }

  it "reports whether all shipping dimensions are available" do
    category = Category.create!(name: "Shipping")
    product = Product.new(name: "Box", price: 50, category: category, weight: 1, width: 10, height: 5, length: 20)

    expect(product).to be_shipping_dimensions_complete

    product.weight = nil
    expect(product).not_to be_shipping_dimensions_complete
  end

  it "uses the RAM and storage combination price" do
    category = Category.create!(name: "Macs")
    product = Product.create!(name: "MacBook Air", price: 7_800, category: category)
    memory = Memory.create!(value: "16GB")
    storage = Storage.create!(value: "512GB")
    ProductVariant.create!(product: product, memory: memory, storage: storage, price: 8_500)

    expect(product.price_for_options(storage: storage, memory: memory)).to eq(8_500)
  end

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
