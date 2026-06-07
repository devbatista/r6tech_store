class Storage < ApplicationRecord
  VALID_STORAGES = ["64GB", "128GB", "256GB", "512GB", "1TB", "2TB"]

  has_many :product_storages, dependent: :destroy
  has_many :products, through: :product_storages
  has_many :product_variants, dependent: :destroy

  validates :value, presence: true, inclusion: { in: VALID_STORAGES }
end
