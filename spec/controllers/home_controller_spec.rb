require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  render_views

  describe "GET #index" do
    it "treats a signed-in user that no longer exists as a visitor" do
      user = User.create!(name: "Ghost", email: "ghost@example.com", password: "password")
      sign_in user
      user.destroy!

      get :index

      expect(response).to have_http_status(:ok)
      expect(controller.current_user).to be_nil
    end

    it "renders storefront sections with products and categories" do
      category = Category.create!(name: "Accessories")
      Product.create!(name: "USB Cable", price: 20, category: category)

      get :index

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("USB Cable")
      expect(response.body).to include("Accessories")
    end

    it "renders an attached category image" do
      category = Category.create!(name: "Category with image")
      category.image.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/product-image.png")),
        filename: "category-image.png",
        content_type: "image/png"
      )

      get :index

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("category-image.png")
    end

    it "renders the used devices WhatsApp call to action" do
      Setting.instance.update!(whatsapp: "(11) 99999-8888", contact_phone: "(11) 11111-2222")

      get :index

      expect(response.body).to include(I18n.t("storefront.home.used_devices.title"))
      expect(response.body).to include("https://wa.me/5511999998888?text=")
      expect(response.body).to include("Gostaria%20de%20conhecer%20os%20aparelhos%20usados%20dispon%C3%ADveis")
    end
  end
end
