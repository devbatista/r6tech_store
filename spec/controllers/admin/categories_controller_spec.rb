require 'rails_helper'

RSpec.describe Admin::CategoriesController, type: :controller do
  render_views

  describe "GET #index" do
    it "filters categories by query" do
      admin = User.create!(
        name: "Admin",
        email: "admin-categories-index@example.com",
        password: "password123",
        role: :admin
      )
      Category.create!(name: "Searchable Accessories")
      Category.create!(name: "Hidden Phones")

      session[:user_id] = admin.id

      get :index, params: { query: "Accessories" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Searchable Accessories")
      expect(response.body).not_to include("Hidden Phones")
    end
  end
end
