require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  render_views

  describe "GET #index" do
    it "renews the session when the signed-in user no longer exists" do
      session[:user_id] = SecureRandom.uuid

      get :index

      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to eq(I18n.t("flash.session_expired"))
    end

    it "renders storefront sections with products and categories" do
      category = Category.create!(name: "Accessories")
      Product.create!(name: "USB Cable", price: 20, category: category)

      get :index

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("USB Cable")
      expect(response.body).to include("Accessories")
    end
  end
end
