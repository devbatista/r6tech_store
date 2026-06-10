require "rails_helper"

RSpec.describe Shipping::CheckoutQuotes do
  it "uses the store shipping rule when Melhor Envio is not configured" do
    category = Category.create!(name: "Fixed shipping")
    product = Product.create!(name: "Cable", price: 20, category: category)
    cart = Cart.create!(status: :active)
    cart.add_product(product)
    setting = Setting.instance
    setting.update!(shipping_fee: 12.50)

    quotes = described_class.call(cart: cart, destination_postal_code: "01310100", setting: setting)

    expect(quotes.first).to include(provider: "store", service_id: "fixed", price: BigDecimal("12.5"))
  end
end
