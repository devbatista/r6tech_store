require 'rails_helper'

RSpec.describe CartItemsController, type: :controller do
  let!(:category) { Category.create!(name: "Accessories") }
  let!(:product) { Product.create!(name: "USB Cable", price: 20, category: category) }

  it "creates and persists a guest cart in the session" do
    post :create, params: { product_id: product.id, quantity: 2 }

    cart = Cart.find(session[:cart_id])
    expect(cart.user).to be_nil
    expect(cart.cart_items.find_by(product: product).quantity).to eq(2)
  end

  it "adds a selected RAM and storage variant with its price" do
    memory = Memory.create!(value: "16GB")
    storage = Storage.create!(value: "512GB")
    variant = ProductVariant.create!(product: product, memory: memory, storage: storage, price: 8_500)

    post :create, params: { product_id: product.id, variant_id: variant.id }

    item = Cart.find(session[:cart_id]).cart_items.find_by!(product: product)
    expect(item.memory).to eq(memory)
    expect(item.storage).to eq(storage)
    expect(item.unit_price).to eq(8_500)
  end

  it "requires a RAM and storage variant when the product has configurations" do
    memory = Memory.create!(value: "16GB")
    storage = Storage.create!(value: "512GB")
    ProductVariant.create!(product: product, memory: memory, storage: storage, price: 8_500)

    post :create, params: { product_id: product.id }

    expect(response).to redirect_to(product_path(product))
    expect(CartItem.where(product: product)).to be_empty
  end

  it "updates an item from the current guest cart" do
    cart = Cart.create!(status: :active)
    item = cart.cart_items.create!(product: product, quantity: 1)
    session[:cart_id] = cart.id

    patch :update, params: { id: item.id, quantity: 3 }

    expect(item.reload.quantity).to eq(3)
  end

  it "removes an item from the current guest cart" do
    cart = Cart.create!(status: :active)
    item = cart.cart_items.create!(product: product, quantity: 1)
    session[:cart_id] = cart.id

    delete :destroy, params: { id: item.id }

    expect(CartItem.exists?(item.id)).to be(false)
  end
end
