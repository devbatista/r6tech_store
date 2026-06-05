class Category < ApplicationRecord
  belongs_to :parent, class_name: "Category", optional: true, foreign_key: "parent_id"
  
  has_many :subcategories, class_name: "Category", foreign_key: "parent_id", dependent: :destroy
  has_many :products, dependent: :nullify

  validates :name, presence: true
  validates :name, uniqueness: { scope: :parent_id }

  validate :cannot_be_own_parent

  scope :roots, -> { where(parent_id: nil) }
  scope :with_subcategories, -> { joins(:subcategories).distinct }

  def descendant_ids
    subcategories.flat_map { |c| [c.id] + c.descendant_ids }
  end

  def full_path(separator = " > ")
    parent ? "#{parent.full_path(separator)}#{separator}#{name}" : name
  end

  def master_parent
    parent.nil? ? self : parent.master_parent
  end

  private

    def cannot_be_own_parent
      if parent_id.present? && (parent_id == id || descendant_ids.include?(parent_id))
        errors.add(:parent_id, :invalid_hierarchy)
      end
    end

end
