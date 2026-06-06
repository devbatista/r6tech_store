class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product
  belongs_to :color, optional: true
  belongs_to :storage, optional: true

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0}

  # Price depends on the chosen storage; colors do not change the price.
  def unit_price
    product.price_for_storage(storage)
  end

  def total_price
    unit_price * quantity
  end
end
