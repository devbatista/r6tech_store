require "rails_helper"

RSpec.describe PaymentsController, type: :controller do
  render_views

  let!(:category) { Category.create!(name: "Accessories") }
  let!(:product) { Product.create!(name: "USB Cable", price: 20, category: category) }
  let!(:user) { User.create!(name: "Customer", email: "customer@example.com", password: "password") }
  let!(:address) do
    user.addresses.create!(
      recipient: user.name,
      zip_code: "01310-100",
      street: "Avenida Paulista",
      number: "1000",
      city: "Sao Paulo",
      state: "SP",
      default: true
    )
  end

  before do
    Setting.instance.update!(pay_pix: true, pay_credit_card: true, pay_boleto: false)
  end

  it "shows the payment step for a signed-in customer with items" do
    session[:user_id] = user.id
    user.carts.create!(status: :active).add_product(product)

    get :new

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("payment-card-fields")
    expect(response.body).to include('autocomplete="cc-number"')
    expect(response.body).not_to include('name="card_number"')
    expect(response.body).not_to include('name="card_cvv"')
  end

  it "creates a pending payment and order from the cart" do
    session[:user_id] = user.id
    cart = user.carts.create!(status: :active)
    cart.add_product(product, 2)

    expect {
      post :create, params: { payment: checkout_params(payment_method: "pix") }
    }.to change(Order, :count).by(1).and change(Payment, :count).by(1)

    payment = Payment.last
    expect(payment).to be_awaiting_payment
    expect(payment.amount).to eq(40)
    expect(payment.order).to eq(Order.last)
    expect(payment.order.shipping_address).to eq(address)
    expect(payment.order.shipping_service_id).to eq("fixed")
    expect(cart.reload).to be_ordered
  end

  it "copies product options to the order item" do
    memory = Memory.create!(value: "24GB")
    storage = Storage.create!(value: "512GB")
    ProductVariant.create!(product: product, memory: memory, storage: storage, price: 11_000)
    session[:user_id] = user.id
    cart = user.carts.create!(status: :active)
    cart.add_product(product, 1, memory: memory, storage: storage)

    post :create, params: { payment: checkout_params(payment_method: "credit_card") }

    item = Order.last.order_items.first
    expect(item.memory).to eq(memory)
    expect(item.storage).to eq(storage)
    expect(item.price).to eq(11_000)
  end

  it "stores only non-sensitive card metadata" do
    session[:user_id] = user.id
    user.carts.create!(status: :active).add_product(product)

    post :create, params: { payment: checkout_params(payment_method: "credit_card", installments: "6") }

    expect(Payment.last.metadata).to eq("installments" => 6)
  end

  it "recalculates the selected shipping option on the server" do
    session[:user_id] = user.id
    user.carts.create!(status: :active).add_product(product, 2)
    quote = {
      provider: "melhor_envio",
      service_id: "99",
      service: "PAC",
      carrier: "Correios",
      price: BigDecimal("15.50"),
      delivery_days: 5
    }
    allow(Shipping::CheckoutQuotes).to receive(:call).and_return([quote])

    post :create, params: {
      payment: checkout_params(payment_method: "pix").merge(shipping_service_id: "99", shipping_price: "0.01")
    }

    expect(Order.last.shipping_cost).to eq(15.50)
    expect(Order.last.total).to eq(55.50)
    expect(Payment.last.amount).to eq(55.50)
  end

  it "rejects checkout without a shipping address" do
    session[:user_id] = user.id
    user.carts.create!(status: :active).add_product(product)

    expect {
      post :create, params: { payment: { payment_method: "pix", shipping_service_id: "fixed" } }
    }.not_to change(Order, :count)

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "rejects a payment method disabled by the store" do
    session[:user_id] = user.id
    user.carts.create!(status: :active).add_product(product)

    expect {
      post :create, params: { payment: { payment_method: "boleto" } }
    }.not_to change(Order, :count)

    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "rejects an unknown payment method without creating an order" do
    session[:user_id] = user.id
    user.carts.create!(status: :active).add_product(product)

    expect {
      post :create, params: { payment: { payment_method: "unknown_gateway" } }
    }.not_to change(Order, :count)

    expect(response).to have_http_status(:unprocessable_entity)
  end

  def checkout_params(payment_method:, installments: nil)
    {
      payment_method: payment_method,
      installments: installments,
      address_id: address.id,
      shipping_service_id: "fixed"
    }.compact
  end
end
