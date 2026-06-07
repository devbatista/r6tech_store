require 'rails_helper'

RSpec.describe ProductsController, type: :controller do
  render_views

  let!(:category) { Category.create!(name: "Accessories") }
  let!(:other_category) { Category.create!(name: "Phones") }
  let!(:cable) { Product.create!(name: "USB Cable", description: "Fast cable", price: 20, category: category) }
  let!(:phone) { Product.create!(name: "Phone", description: "Smart device", price: 100, category: other_category) }

  describe "GET #index" do
    it "searches products by name" do
      get :index, params: { query: "Cable" }

      expect(controller.instance_variable_get(:@products)).to contain_exactly(cable)
    end

    it "filters products by category" do
      get :index, params: { category_id: category.id }

      expect(controller.instance_variable_get(:@products)).to contain_exactly(cable)
    end

    it "sorts products by descending price" do
      get :index, params: { sort: "price_desc" }

      expect(controller.instance_variable_get(:@products).to_a).to eq([phone, cable])
    end
  end

  describe "GET #show" do
    it "renders a product without an attached image" do
      get :show, params: { id: cable.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(cable.name)
      expect(response.body).to include("storefront/product-placeholder")
    end

    it "renders selectable RAM and storage configurations" do
      memory = Memory.create!(value: "24GB")
      storage = Storage.create!(value: "512GB")
      ProductVariant.create!(product: cable, memory: memory, storage: storage, price: 11_000)

      get :show, params: { id: cable.id }

      expect(response.body).to include("24GB RAM")
      expect(response.body).to include("512GB")
      expect(response.body).to include("11.000,00")
    end
  end
end
