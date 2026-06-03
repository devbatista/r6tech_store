class Product < ApplicationRecord
  has_many :cart_items
  has_many :order_items
  has_many :product_stocks, dependent: :destroy

  belongs_to :category

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :stock, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :category, presence: true

  before_destroy :ensure_no_orders_or_stock
  before_destroy :clean_up_stock_before_destroy

  has_many_attached :images

  def stock_quantity
    if association(:product_stocks).loaded?
      product_stocks.sum(&:quantity)
    else
      product_stocks.sum(:quantity)
    end
  end

  def in_stock?
    stock_quantity.positive?
  end

  private

    def ensure_no_orders_or_stock
      if order_items.exists?
        errors.add(:base, 'Cannot delete product with associated orders')
        throw(:abort)
      end

      if in_stock?
        errors.add(:base, 'Cannot delete product with stock')
        throw(:abort)
      end
    end

    def clean_up_stock_before_destroy
      product_stocks.destroy_all if product_stocks.any?
    end
end
