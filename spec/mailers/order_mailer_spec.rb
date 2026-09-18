require "rails_helper"

RSpec.describe OrderMailer, type: :mailer do
  let!(:category) { Category.create!(name: "Phones") }
  let!(:product) { Product.create!(name: "iPhone 15", price: 5000, category: category) }
  let!(:user) { User.create!(name: "Maria Silva", email: "maria@example.com", password: "password") }
  let!(:order) do
    order = user.orders.create!(
      status: :pending, total: 5030, shipping_cost: 30, shipping_service: "PAC", shipping_delivery_days: 5,
      shipping_recipient: "Maria Silva", shipping_street: "Av. Paulista", shipping_number: "1000",
      shipping_city: "São Paulo", shipping_state: "SP", shipping_zip_code: "01310-100", shipping_country: "Brasil"
    )
    order.order_items.create!(product: product, quantity: 2, price: 2500)
    order
  end
  let(:order_number) { order.id.to_s.first(8).upcase }

  before { Setting.instance.update!(store_name: "R6Tech", notification_sender: "vendas@r6tech.store") }

  describe "#confirmation" do
    subject(:mail) { described_class.with(order: order).confirmation }

    it "is sent from the store to the customer" do
      expect(mail[:from].to_s).to eq("R6Tech <vendas@r6tech.store>")
      expect(mail[:to].to_s).to eq("Maria Silva <maria@example.com>")
      expect(mail.subject).to eq(I18n.t("order_mailer.confirmation.subject", number: order_number, store: "R6Tech"))
    end

    it "summarizes the order in both parts" do
      [mail.html_part, mail.text_part].each do |part|
        body = part.body.decoded
        expect(body).to include("Olá, Maria!")
        expect(body).to include("iPhone 15")
        expect(body).to include("R$ 5.000,00")
        expect(body).to include("R$ 30,00")
        expect(body).to include("R$ 5.030,00")
        expect(body).to include("Av. Paulista, 1000")
        expect(body).to include("http://www.example.com/account?order_id=#{order.id}")
      end
    end
  end

  describe "#shipped" do
    subject(:mail) { described_class.with(order: order).shipped }

    it "includes the delivery estimate" do
      expect(mail.subject).to include("foi enviado")
      expect(mail.text_part.body.decoded).to include("Prazo estimado: 5 dias úteis.")
    end
  end

  describe "#paid and #delivered" do
    it "use their own subjects" do
      expect(described_class.with(order: order).paid.subject).to include("Pagamento confirmado")
      expect(described_class.with(order: order).delivered.subject).to include("foi entregue")
    end
  end

  it "falls back to the default sender and store name when settings are blank" do
    Setting.instance.update!(store_name: nil, notification_sender: nil)

    mail = described_class.with(order: order).confirmation

    expect(mail[:from].to_s).to eq("#{Setting::DEFAULT_STORE_NAME} <#{Setting::DEFAULT_SENDER}>")
  end
end
