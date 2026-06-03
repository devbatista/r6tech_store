require 'rails_helper'

RSpec.describe Category, type: :model do
  describe "associations" do
    it { should belong_to(:parent).class_name('Category').optional }
    it { should have_many(:products).dependent(:nullify) }
    it { should have_many(:subcategories).class_name('Category').with_foreign_key('parent_id').dependent(:destroy) }
  end

  describe "validations" do
    subject { Category.new(name: "Test") }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:parent_id).with_message("must be unique per parent category") } 
  end

  describe "custom validations: cannot_be_own_parent" do
    it "does not allow a category to be its own parent" do
      category = Category.create!(name: 'Root')
      category.parent = category
      expect(category.valid?).to(be_falsey)
      expect(category.errors[:parent_id]).to(include("can't be itself or a descendant"))
    end

    it "does not allow a category to be a descendant of itself" do
      root = Category.create!(name: 'Root')
      child = Category.create!(name: 'Child', parent: root)
      root.parent = child
      expect(root.valid?).to(be_falsey)
      expect(root.errors[:parent_id]).to(include("can't be itself or a descendant"))
    end
  end

  describe "#full_path" do
    it "returns only the name for a root category" do
      root = Category.create!(name: 'Root')
      expect(root.full_path).to(eq("Root"))
    end

    it "returns the full path for a nested category" do
      root = Category.create!(name: 'Root')
      child = Category.create!(name: 'Child', parent: root)
      grandchild = Category.create!(name: 'Grandchild', parent: child)
      expect(grandchild.full_path).to(eq("Root > Child > Grandchild"))
    end
  end

  describe "products relationships" do
    it "can have many products" do
      category = Category.create!(name: "Electronics")
      product1 = Product.create!(name: "TV", price: 1000, category: category)
      product2 = Product.create!(name: "Radio", price: 100, category: category)
      expect(category.products).to(include(product1, product2))
      expect(category.products.count).to(eq(2))
    end

    it "nullifies product category on category destroy" do
      category = Category.create!(name: "Books")
      product = Product.create!(name: "Shop book", price: 50, category: category)
      category.destroy
      expect(product.reload.category_id).to(be_nil)
    end
  end
end
