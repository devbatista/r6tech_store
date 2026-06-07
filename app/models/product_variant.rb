class ProductVariant < ApplicationRecord
  belongs_to :product
  belongs_to :memory
  belongs_to :storage

  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :storage_id, uniqueness: { scope: [:product_id, :memory_id] }
end
