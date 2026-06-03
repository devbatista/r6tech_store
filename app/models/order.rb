class Order < ApplicationRecord
  belongs_to :user
  has_many :order_items, dependent: :destroy

  enum :status, {
    pending: "pending",
    paid: "paid",
    shipped: "shipped",
    delivered: "delivered",
    cancelled: "cancelled"
  }

  validates :status, presence: true
  validates :total, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
