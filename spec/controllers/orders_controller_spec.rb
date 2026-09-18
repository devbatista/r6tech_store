require 'rails_helper'

RSpec.describe OrdersController, type: :controller do
  let!(:category) { Category.create!(name: "Accessories") }
  let!(:product) { Product.create!(name: "USB Cable", price: 20, category: category) }
  let!(:user) { User.create!(name: "Customer", email: "customer@example.com", password: "password") }

  it "redirects a visitor to login before checkout" do
    post :create

    expect(response).to redirect_to(new_user_session_path)
  end

  it "redirects checkout to the payment step" do
    sign_in user
    cart = user.carts.create!(status: :active)
    cart.add_product(product, 2)

    expect { post :create }.not_to change(Order, :count)

    expect(response).to redirect_to(new_payment_path)
    expect(cart.reload).to be_active
  end
end

RSpec.describe OrdersController, "pagamento", type: :controller do
  let!(:user) { User.create!(name: "Customer", email: "customer@example.com", password: "password") }
  let!(:order) { user.orders.create!(status: :pending, total: 100) }
  let!(:payment) { order.create_payment!(payment_method: :pix, amount: 100, status: :awaiting_payment) }

  before { sign_in user }

  describe "POST #pay" do
    it "sends the customer to the hosted checkout" do
      allow(Payments::Checkout).to receive(:call).with(payment: payment).and_return("https://mp.example/checkout")

      post :pay, params: { id: order.id }

      expect(response).to redirect_to("https://mp.example/checkout")
    end

    it "refuses orders that are not awaiting payment" do
      payment.update!(status: :paid)

      post :pay, params: { id: order.id }

      expect(response).to redirect_to(order_path(order))
      expect(flash[:alert]).to eq(I18n.t("storefront.payment.not_payable"))
    end

    it "explains when the gateway is unavailable" do
      allow(Payments::Checkout).to receive(:call).and_raise(Payments::ProviderError, "down")

      post :pay, params: { id: order.id }

      expect(response).to redirect_to(order_path(order))
      expect(flash[:alert]).to eq(I18n.t("storefront.payment.checkout_unavailable"))
    end

    it "does not expose other customers' orders" do
      other = User.create!(name: "Other", email: "other@example.com", password: "password")
      other_order = other.orders.create!(status: :pending, total: 10)

      expect { post :pay, params: { id: other_order.id } }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "GET #payment_return" do
    it "syncs the payment reported by the gateway and shows the result" do
      allow(Payments::Sync).to receive(:call).with(provider_payment_id: "987") { payment.update!(status: :paid) }

      get :payment_return, params: { id: order.id, payment_id: "987", status: "approved" }

      expect(response).to redirect_to(order_path(order))
      expect(flash[:notice]).to eq(I18n.t("storefront.payment.return_notice.paid"))
    end

    it "does not trust the status in the query string" do
      allow(Payments::Sync).to receive(:call)

      get :payment_return, params: { id: order.id, status: "approved" }

      expect(Payments::Sync).not_to have_received(:call)
      expect(payment.reload).to be_awaiting_payment
      expect(flash[:notice]).to eq(I18n.t("storefront.payment.return_notice.awaiting_payment"))
    end

    it "still shows the order when the gateway lookup fails" do
      allow(Payments::Sync).to receive(:call).and_raise(Payments::ProviderError, "down")

      get :payment_return, params: { id: order.id, payment_id: "987" }

      expect(response).to redirect_to(order_path(order))
      expect(flash[:notice]).to eq(I18n.t("storefront.payment.return_notice.awaiting_payment"))
    end
  end

  describe "GET #show" do
    render_views

    it "offers the pay button while the payment is open" do
      get :show, params: { id: order.id }

      expect(response.body).to include(I18n.t("storefront.payment.pay_now"))
      expect(response.body).to include(pay_order_path(order))
    end

    it "hides the pay button once paid" do
      order.update!(status: :paid)

      get :show, params: { id: order.id }

      expect(response.body).not_to include(I18n.t("storefront.payment.pay_now"))
    end
  end
end
