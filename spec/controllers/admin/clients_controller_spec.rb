require 'rails_helper'

RSpec.describe Admin::ClientsController, type: :controller do
  render_views

  describe "GET #index" do
    it "filters clients by query" do
      admin = User.create!(
        name: "Admin",
        email: "admin-clients-index@example.com",
        password: "password123",
        role: :admin
      )
      User.create!(
        name: "Searchable Client",
        email: "searchable-client@example.com",
        password: "password123",
        role: :customer
      )
      User.create!(
        name: "Hidden Client",
        email: "hidden-client@example.com",
        password: "password123",
        role: :customer
      )

      session[:user_id] = admin.id

      get :index, params: { query: "searchable-client" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Searchable Client")
      expect(response.body).not_to include("Hidden Client")
    end
  end
end
