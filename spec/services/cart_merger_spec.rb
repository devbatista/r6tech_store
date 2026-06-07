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

  it "preserves RAM and storage selections" do
    category = Category.create!(name: "Macs")
    product = Product.create!(name: "MacBook Air", price: 8_500, category: category)
    memory = Memory.create!(value: "16GB")
    storage = Storage.create!(value: "512GB")
    ProductVariant.create!(product: product, memory: memory, storage: storage, price: 8_500)
    user = User.create!(name: "Customer", email: "mac-customer@example.com", password: "password")
    guest_cart = Cart.create!(status: :active)
    guest_cart.add_product(product, 1, memory: memory, storage: storage)

    cart = described_class.new(user: user, guest_cart: guest_cart).call

    item = cart.cart_items.find_by!(product: product)
    expect(item.memory).to eq(memory)
    expect(item.storage).to eq(storage)
  end
end
