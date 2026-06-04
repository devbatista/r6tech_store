require "rails_helper"

RSpec.describe Setting, type: :model do
  it "forces the currency to Brazilian Real" do
    setting = described_class.create!(currency: "USD")

    expect(setting.currency).to eq("BRL")
  end
end
