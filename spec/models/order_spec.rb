require "rails_helper"

RSpec.describe Order, type: :model do
  it { should belong_to(:user) }
  it { should have_many(:order_items).dependent(:destroy) }
  it { should have_one(:payment).dependent(:destroy) }

  it { should validate_presence_of(:status) }
  it { should validate_presence_of(:total) }
  it { should validate_numericality_of(:total).is_greater_than_or_equal_to(0) }

  it "valid_statuses" do
  valid_statuses = %w[pending paid shipped delivered cancelled]
  valid_statuses.each do |status|
    order = Order.new(status: status, total: 10)
    order.validate
    expect(order.errors[:status]).to be_empty, "expected status '#{status}' to be valid"
  end

  expect {
    Order.new(status: "invalid", total: 10)
  }.to raise_error(ArgumentError)
end

  it "synchronizes a manual paid status with its payment" do
    user = User.create!(name: "Customer", email: "payment-customer@example.com", password: "password")
    order = user.orders.create!(status: :pending, total: 100)
    payment = order.create_payment!(payment_method: :pix, status: :awaiting_payment, amount: 100)

    order.update!(status: :paid)

    expect(payment.reload).to be_paid
  end

  it "creates an order with the selected shipping quote and address" do
    category = Category.create!(name: "Shipping order")
    product = Product.create!(name: "Box", price: 100, category: category)
    user = User.create!(name: "Customer", email: "shipping-order@example.com", password: "password")
    address = user.addresses.create!(zip_code: "01310100", street: "Paulista", city: "Sao Paulo", state: "SP")
    cart = user.carts.create!(status: :active)
    cart.add_product(product)
    quote = {
      provider: "melhor_envio",
      service_id: "1",
      service: "PAC",
      carrier: "Correios",
      price: BigDecimal("25.50"),
      delivery_days: 6
    }

    order = described_class.create_from_cart!(user: user, cart: cart, shipping_address: address, shipping_quote: quote)

    expect(order.total).to eq(125.50)
    expect(order.shipping_cost).to eq(25.50)
    expect(order.shipping_service).to eq("PAC")
    expect(order.shipping_zip_code).to eq("01310100")
  end
end
