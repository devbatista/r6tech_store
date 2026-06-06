class Product < ApplicationRecord
  AI_STATUSES = %w[idle pending ready approved failed].freeze

  has_many :cart_items
  has_many :order_items

  has_many :product_colors, dependent: :destroy
  has_many :colors, through: :product_colors
  has_many :product_storages, dependent: :destroy
  has_many :storages, through: :product_storages

  belongs_to :category

  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :category, presence: true
  validates :ai_description_status, inclusion: { in: AI_STATUSES }
  validates :ai_image_status, inclusion: { in: AI_STATUSES }

  before_destroy :ensure_no_orders

  has_many_attached :images
  has_many_attached :ai_generated_images

  def needs_ai_suggestions?
    description.blank? || !images.attached?
  end

  # Whether the product offers selectable color/storage options.
  def options?
    product_colors.any? || product_storages.any?
  end

  # Lowest available price across storages ("a partir de"); falls back to the
  # flat price for products without storage options.
  def from_price
    product_storages.minimum(:price) || price
  end

  # Price for a given storage option, falling back to the flat price.
  def price_for_storage(storage)
    return price if storage.nil?

    product_storages.find_by(storage_id: storage.id)&.price || price
  end

  private

    def ensure_no_orders
      if order_items.exists?
        errors.add(:base, 'Cannot delete product with associated orders')
        throw(:abort)
      end
    end
end
