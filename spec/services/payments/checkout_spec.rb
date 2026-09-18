require "rails_helper"

RSpec.describe Payments::Checkout do
  let!(:category) { Category.create!(name: "Phones") }
  let!(:product) { Product.create!(name: "iPhone 15", price: 5000, category: category) }
  let!(:user) { User.create!(name: "Maria Silva", email: "maria@example.com", password: "password") }
  let!(:order) do
    user.orders.create!(status: :pending, total: 5030, shipping_cost: 30, shipping_service: "PAC").tap do |order|
      order.order_items.create!(product: product, quantity: 1, price: 5000)
    end
  end
  let!(:payment) { order.create_payment!(payment_method: :pix, amount: 5030, status: :awaiting_payment) }
  let(:client) { Payments::Providers::MercadoPago::Client.new(access_token: "TEST-token") }

  before { Setting.instance.update!(store_name: "R6Tech") }

  def stub_preference(response_body = { id: "pref-123", init_point: "https://www.mercadopago.com.br/checkout/v1/redirect?pref_id=pref-123" })
    stub_request(:post, "https://api.mercadopago.com/checkout/preferences").to_return(
      status: 201, body: response_body.to_json, headers: { "Content-Type" => "application/json" }
    )
  end

  it "creates a Checkout Pro preference and stores it on the payment" do
    stub = stub_preference

    url = described_class.call(payment: payment, client: client)

    expect(url).to eq("https://www.mercadopago.com.br/checkout/v1/redirect?pref_id=pref-123")
    expect(payment.reload.provider).to eq("mercado_pago")
    expect(payment.metadata["preference_id"]).to eq("pref-123")
    expect(payment.checkout_url).to eq(url)

    expect(stub.with { |request|
      body = JSON.parse(request.body)
      request.headers["Authorization"] == "Bearer TEST-token" &&
        request.headers["X-Idempotency-Key"] == payment.id &&
        body["external_reference"] == order.id &&
        body["items"] == [{ "id" => product.id, "title" => "iPhone 15", "category_id" => "electronics", "quantity" => 1, "unit_price" => 5000.0, "currency_id" => "BRL" }] &&
        body["shipments"] == { "mode" => "not_specified", "cost" => 30.0 } &&
        body["payer"] == { "name" => "Maria", "surname" => "Silva", "email" => "maria@example.com" } &&
        body["statement_descriptor"] == "R6TECH" &&
        body["back_urls"]["success"] == "http://www.example.com/orders/#{order.id}/payment/return" &&
        body["auto_return"] == "approved" &&
        body["metadata"] == { "order_id" => order.id, "payment_id" => payment.id } &&
        !body.key?("notification_url")
    }).to have_been_requested
  end

  it "restricts the hosted checkout to the method chosen in the store" do
    stub = stub_preference

    described_class.call(payment: payment, client: client)

    expect(stub.with { |request|
      excluded = JSON.parse(request.body).dig("payment_methods", "excluded_payment_types").map { |type| type["id"] }
      excluded.sort == %w[atm credit_card debit_card prepaid_card ticket]
    }).to have_been_requested
  end

  it "sends the webhook URL only when the store host is served over https" do
    stub = stub_preference
    allow(Rails.application.config.action_mailer).to receive(:default_url_options).and_return(host: "r6tech.store", protocol: "https")

    described_class.call(payment: payment, client: client)

    expect(stub.with { |request| JSON.parse(request.body)["notification_url"] == "https://r6tech.store/webhooks/mercado_pago" }).to have_been_requested
  end

  it "reuses the stored checkout URL instead of creating another preference" do
    payment.update!(metadata: { "init_point" => "https://mp.example/existing" })

    expect(described_class.call(payment: payment, client: client)).to eq("https://mp.example/existing")
    expect(a_request(:post, /preferences/)).not_to have_been_made
  end

  it "refuses payments that are no longer payable" do
    payment.update!(status: :paid)

    expect { described_class.call(payment: payment, client: client) }.to raise_error(Payments::Error)
  end

  it "raises a configuration error without an access token" do
    expect {
      described_class.call(payment: payment, client: Payments::Providers::MercadoPago::Client.new(access_token: nil))
    }.to raise_error(Payments::ConfigurationError)
  end

  it "wraps API errors" do
    stub_request(:post, "https://api.mercadopago.com/checkout/preferences")
      .to_return(status: 400, body: { message: "invalid items" }.to_json)

    expect { described_class.call(payment: payment, client: client) }
      .to raise_error(Payments::ProviderError, "invalid items")
  end
end
