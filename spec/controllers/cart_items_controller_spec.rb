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
