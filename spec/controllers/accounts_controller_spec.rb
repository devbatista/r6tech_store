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

  it "updates the customer's name and email" do
    session[:user_id] = user.id

    patch :update, params: { user: { name: "Updated Customer", email: "updated-customer@example.com" } }

    expect(user.reload).to have_attributes(name: "Updated Customer", email: "updated-customer@example.com")
    expect(response).to redirect_to(account_path(anchor: "details"))
  end

  it "updates the customer's password with the current password" do
    session[:user_id] = user.id

    patch :update, params: { user: { current_password: "password", password: "new-password", password_confirmation: "new-password" } }

    expect(user.reload.valid_password?("new-password")).to be(true)
  end

  it "does not update the password with an invalid current password" do
    session[:user_id] = user.id

    patch :update, params: { user: { current_password: "wrong", password: "new-password", password_confirmation: "new-password" } }

    expect(user.reload.valid_password?("password")).to be(true)
  end
end
