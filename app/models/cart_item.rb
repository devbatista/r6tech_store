class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :product
  belongs_to :color, optional: true
  belongs_to :storage, optional: true
  belongs_to :memory, optional: true

  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0}

  # Price depends on the chosen variation (color + RAM + storage) or storage.
  def unit_price
    product.price_for_options(storage: storage, memory: memory, color: color)
  end

  def total_price
    unit_price * quantity
  end
end
