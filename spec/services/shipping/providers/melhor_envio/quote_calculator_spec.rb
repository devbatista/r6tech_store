require "rails_helper"

RSpec.describe Shipping::Providers::MelhorEnvio::QuoteCalculator do
  let(:category) { Category.create!(name: "Accessories") }
  let(:product) do
    Product.create!(
      name: "USB Cable",
      price: 20,
      category: category,
      weight: 0.2,
      width: 12,
      height: 4,
      length: 18
    )
  end
  let(:cart) { Cart.create!(status: :active).tap { |record| record.add_product(product, 2) } }
  let(:client) { instance_double(Shipping::Providers::MelhorEnvio::Client) }
  subject(:calculator) { described_class.new(client: client, origin_postal_code: "01001-000") }

  it "sends the cart in Melhor Envio's product format and normalizes quotes" do
    allow(client).to receive(:calculate).and_return(
      [
        {
          "id" => 1,
          "name" => "PAC",
          "price" => "25.50",
          "delivery_time" => 6,
          "company" => { "name" => "Correios" }
        },
        { "id" => 2, "error" => "Service unavailable" }
      ]
    )

    quotes = calculator.call(cart: cart, destination_postal_code: "01310-100")

    expect(client).to have_received(:calculate).with(
      from: { postal_code: "01001000" },
      to: { postal_code: "01310100" },
      products: [
        {
          id: product.id,
          width: 12.0,
          height: 4.0,
          length: 18.0,
          weight: 0.2,
          insurance_value: 20.0,
          quantity: 2
        }
      ]
    )
    expect(quotes.first).to include(
      provider: "melhor_envio",
      service: "PAC",
      carrier: "Correios",
      price: BigDecimal("25.50"),
      delivery_days: 6
    )
    expect(quotes.size).to eq(1)
  end

  it "rejects products without shipping dimensions before calling the provider" do
    allow(client).to receive(:calculate)
    product.update!(weight: nil)

    expect {
      calculator.call(cart: cart, destination_postal_code: "01310100")
    }.to raise_error(Shipping::InvalidPackageError, /USB Cable/)

    expect(client).not_to have_received(:calculate)
  end

  it "rejects invalid destination postal codes" do
    expect {
      calculator.call(cart: cart, destination_postal_code: "123")
    }.to raise_error(Shipping::InvalidPackageError, /8 digits/)
  end
end
