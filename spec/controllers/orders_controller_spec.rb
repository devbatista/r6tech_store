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
end
