require "rails_helper"

RSpec.describe Shipping::Providers::MelhorEnvio::Client do
  it "requires a token before making a request" do
    client = described_class.new(token: nil)

    expect {
      client.calculate(from: {}, to: {}, products: [])
    }.to raise_error(Shipping::ConfigurationError, /MELHOR_ENVIO_TOKEN/)
  end
end
