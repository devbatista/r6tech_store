require "rails_helper"

RSpec.describe CartMerger do
  it "moves guest items into the customer active cart" do
    category = Category.create!(name: "Accessories")
    product = Product.create!(name: "Cable", price: 20, category: category)
    user = User.create!(name: "Customer", email: "customer@example.com", password: "password")
    guest_cart = Cart.create!(status: :active)
    guest_cart.add_product(product, 2)

    cart = described_class.new(user: user, guest_cart: guest_cart).call

    expect(cart.cart_items.find_by(product: product).quantity).to eq(2)
    expect(guest_cart.reload).to be_abandoned
  end

  it "merges quantities when the customer already has the product" do
    category = Category.create!(name: "Accessories")
    product = Product.create!(name: "Cable", price: 20, category: category)
    user = User.create!(name: "Customer", email: "customer@example.com", password: "password")
    user_cart = user.carts.create!(status: :active)
    user_cart.add_product(product, 1)
    guest_cart = Cart.create!(status: :active)
    guest_cart.add_product(product, 2)

    cart = described_class.new(user: user, guest_cart: guest_cart).call

    expect(cart.cart_items.find_by(product: product).quantity).to eq(3)
  end
end
