require "rails_helper"

RSpec.describe OrderItem, type: :model do
  it { should belong_to(:order) }
  it { should belong_to(:product) }

  it { should validate_presence_of(:quantity) }
  it { should validate_numericality_of(:quantity).only_integer.is_greater_than(0) }
  it { should validate_presence_of(:price) }
  
  describe "validação de preço" do
    let(:user) { User.create!(name: "Teste", email: "teste@email.com", password: "123456") }
    let(:order) { Order.create!(user: user, status: "pending", total: 10) }
    let(:category) { Category.create!(name: "Produtos") }
    let(:product) { Product.create!(name: "Produto", price: 10, category: category) }

    it "não permite preço negativo" do
      order_item = OrderItem.new(order: order, product: product, quantity: 1, price: -1)
      expect(order_item).not_to be_valid
      expect(order_item.errors[:price]).to include(I18n.t("errors.messages.greater_than_or_equal_to", count: 0))
    end
  end
end
