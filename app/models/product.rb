class Product < ApplicationRecord
  has_many :cart_items
  has_many :order_items

  belongs_to :category

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :category, presence: true

  before_destroy :ensure_no_orders

  has_many_attached :images

  private

    def ensure_no_orders
      if order_items.exists?
        errors.add(:base, 'Cannot delete product with associated orders')
        throw(:abort)
      end
    end
end
