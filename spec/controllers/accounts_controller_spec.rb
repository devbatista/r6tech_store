require "rails_helper"

RSpec.describe AccountsController, type: :controller do
  render_views

  let!(:user) { User.create!(name: "Customer", email: "customer-account@example.com", password: "password") }

  it "redirects visitors to login" do
    get :show

    expect(response).to redirect_to(login_path)
  end

  it "renders the account dashboard for customers" do
    session[:user_id] = user.id

    get :show

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Customer")
  end

  it "renders an order detail inside the account page" do
    session[:user_id] = user.id
    order = user.orders.create!(status: :pending, total: 100)

    get :show, params: { order_id: order.id }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("account_orders_content")
    expect(response.body).to include(order.id.to_s.first(8))
  end

  it "renders an address form inside the account page" do
    session[:user_id] = user.id

    get :show, params: { new_address: 1 }

    expect(response.body).to include("account_addresses_content")
    expect(response.body).to include("account-address-form")
  end
end
