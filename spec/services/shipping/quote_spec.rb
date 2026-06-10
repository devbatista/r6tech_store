require "rails_helper"

RSpec.describe Shipping::Quote do
  it "delegates to the configured provider" do
    provider = instance_double(Shipping::Providers::MelhorEnvio::QuoteCalculator)
    cart = instance_double(Cart)
    allow(provider).to receive(:call).and_return([{ service: "PAC" }])

    result = described_class.call(cart: cart, destination_postal_code: "01310100", provider: provider)

    expect(result).to eq([{ service: "PAC" }])
    expect(provider).to have_received(:call).with(cart: cart, destination_postal_code: "01310100")
  end
end
