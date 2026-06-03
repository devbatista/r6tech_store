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
end
