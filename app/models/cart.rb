class Cart < ApplicationRecord
  belongs_to :user
  has_many :cart_items, dependent: :destroy
  
  enum :status, {
    active: 1,
    abandoned: 2,
    ordered: 3,
    cancelled: 0
  }

  validates :status, presence: true

  def total_value
    cart_items.includes(:product).sum { |item| item.quantity * item.product.price }
  end

  def add_product(product, quantity = 1)
    return { success: false, errors: "Insufficient stock" } if product.stock < quantity

    cart_item = cart_items.find_or_initialize_by(product: product)
    cart_item.quantity ||= 0
    cart_item.quantity += quantity
    cart_item.save
  end

  def remove_product(product)
    item = cart_item.find_by(product: product)

    return { success: false, errors: "Item not found"} if item.nil?
    item.destroy
  end
end
