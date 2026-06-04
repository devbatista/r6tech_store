class Product < ApplicationRecord
  AI_STATUSES = %w[idle pending ready approved failed].freeze

  has_many :cart_items
  has_many :order_items

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

  private

    def ensure_no_orders
      if order_items.exists?
        errors.add(:base, 'Cannot delete product with associated orders')
        throw(:abort)
      end
    end
end
