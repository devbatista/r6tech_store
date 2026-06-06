class Cart < ApplicationRecord
  belongs_to :user, optional: true
  has_many :cart_items, dependent: :destroy
  
  enum :status, {
    active: 1,
    abandoned: 2,
    ordered: 3,
    cancelled: 0
  }

  validates :status, presence: true

  def total_value
    cart_items.includes(:product, :storage).sum(&:total_price)
  end

  def shipping_cost(setting = Setting.instance)
    threshold = setting.free_shipping_threshold
    return 0 if threshold.present? && total_value >= threshold

    setting.shipping_fee || 0
  end

  def total_with_shipping(setting = Setting.instance)
    total_value + shipping_cost(setting)
  end

  def add_product(product, quantity = 1, color: nil, storage: nil)
    return false if quantity.to_i <= 0

    cart_item = cart_items.find_or_initialize_by(product: product, color: color, storage: storage)
    cart_item.quantity ||= 0
    cart_item.quantity += quantity.to_i
    cart_item.save
  end

  def remove_product(product)
    item = cart_item.find_by(product: product)

    return { success: false, errors: I18n.t("flash.cart_item_not_found", default: "Item nao encontrado") } if item.nil?
    item.destroy
  end
end
