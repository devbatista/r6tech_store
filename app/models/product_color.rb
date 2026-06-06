class ProductColor < ApplicationRecord
  belongs_to :product
  belongs_to :color

  validates :color_id, uniqueness: { scope: :product_id }
end
