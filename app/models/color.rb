class Color < ApplicationRecord
  has_many :product_colors, dependent: :destroy
  has_many :products, through: :product_colors

  validates :name, presence: true
  validates :hex, presence: true, format: { with: /\A#(?:[0-9a-fA-F]{3}){1,2}\z/ }
end