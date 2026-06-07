class Memory < ApplicationRecord
  VALID_MEMORIES = ["8GB", "16GB", "24GB", "32GB", "36GB", "48GB", "64GB", "96GB", "128GB"].freeze

  has_many :product_variants, dependent: :destroy
  has_many :products, through: :product_variants

  validates :value, presence: true, inclusion: { in: VALID_MEMORIES }, uniqueness: true
end
