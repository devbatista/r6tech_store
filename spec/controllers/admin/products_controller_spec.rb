require 'rails_helper'

RSpec.describe Admin::ProductsController, type: :controller do
  render_views

  describe "GET #show" do
    it "renders the product detail page" do
      admin = User.create!(
        name: "Admin",
        email: "admin@example.com",
        password: "password123",
        role: :admin
      )
      category = Category.create!(name: "Phones")
      product = Product.create!(
        name: "iPhone 15",
        description: "A reliable phone for daily use.",
        price: 4999.90,
        category: category
      )

      session[:user_id] = admin.id

      get :show, params: { id: product.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("iPhone 15")
      expect(response.body).to include("Phones")
      expect(response.body).to include("No product images")
      expect(response.body).to include("Add images")
      expect(response.body).to include("Edit")
    end
  end

  describe "PATCH #update" do
    it "updates an existing product" do
      admin = User.create!(
        name: "Admin",
        email: "admin-update@example.com",
        password: "password123",
        role: :admin
      )
      category = Category.create!(name: "Notebooks")
      product = Product.create!(
        name: "Old product",
        description: "Old description",
        price: 1000,
        category: category
      )

      session[:user_id] = admin.id

      patch :update, params: {
        id: product.id,
        product: {
          name: "Updated product",
          description: "Updated description",
          price: 1200,
          category_id: category.id
        }
      }

      expect(response).to redirect_to(admin_product_path(product))
      expect(product.reload.name).to eq("Updated product")
      expect(product.description).to eq("Updated description")
      expect(product.price).to eq(1200)
    end
  end
end
