require 'rails_helper'

RSpec.describe OrdersController, type: :controller do
  let!(:category) { Category.create!(name: "Accessories") }
  let!(:product) { Product.create!(name: "USB Cable", price: 20, category: category) }
  let!(:user) { User.create!(name: "Customer", email: "customer@example.com", password: "password") }

  it "redirects a visitor to login before checkout" do
    post :create

    expect(response).to redirect_to(login_path)
  end

  it "creates an order from the active customer cart" do
    session[:user_id] = user.id
    cart = user.carts.create!(status: :active)
    cart.add_product(product, 2)

    expect { post :create }.to change(Order, :count).by(1)

    expect(Order.last.total).to eq(40)
    expect(cart.reload).to be_ordered
  end

  it "copies RAM and storage selections to the order item" do
    memory = Memory.create!(value: "24GB")
    storage = Storage.create!(value: "512GB")
    ProductVariant.create!(product: product, memory: memory, storage: storage, price: 11_000)
    session[:user_id] = user.id
    cart = user.carts.create!(status: :active)
    cart.add_product(product, 1, memory: memory, storage: storage)

    post :create

    item = Order.last.order_items.first
    expect(item.memory).to eq(memory)
    expect(item.storage).to eq(storage)
    expect(item.price).to eq(11_000)
  end
end
