require "rails_helper"

RSpec.describe Users::SessionsController, type: :controller do
  let!(:category) { Category.create!(name: "Accessories") }
  let!(:product) { Product.create!(name: "USB Cable", price: 20, category: category) }
  let!(:customer) { User.create!(name: "Customer", email: "customer@example.com", password: "password") }
  let!(:admin) { User.create!(name: "Admin", email: "admin@example.com", password: "password", role: :admin) }

  before { @request.env["devise.mapping"] = Devise.mappings[:user] }

  describe "GET #new" do
    it "opens the login modal on the home page" do
      get :new

      expect(response).to redirect_to(root_path(anchor: "login-modal"))
    end
  end

  describe "POST #create" do
    it "signs in a customer and merges the guest cart" do
      guest_cart = Cart.create!(status: :active)
      guest_cart.cart_items.create!(product: product, quantity: 2)
      session[:cart_id] = guest_cart.id

      post :create, params: { user: { email: customer.email, password: "password" } }

      expect(controller.current_user).to eq(customer)
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq(I18n.t("flash.login_successful"))
      expect(session[:cart_id]).to be_nil
      expect(customer.carts.find_by(status: :active).cart_items.sum(:quantity)).to eq(2)
      expect(guest_cart.reload).to be_abandoned
    end

    it "returns to the stored location after signing in" do
      controller.store_location_for(:user, new_payment_path)

      post :create, params: { user: { email: customer.email, password: "password" } }

      expect(response).to redirect_to(new_payment_path)
    end

    it "sends administrators to the admin panel" do
      post :create, params: { user: { email: admin.email, password: "password" } }

      expect(controller.current_user).to eq(admin)
      expect(response).to redirect_to(admin_root_path)
    end

    it "reopens the modal with the email filled in when credentials are invalid" do
      post :create, params: { user: { email: customer.email, password: "wrong" } }

      expect(controller.current_user).to be_nil
      expect(response).to redirect_to(root_path(email: customer.email, anchor: "login-modal"))
      expect(flash[:alert]).to eq(I18n.t("flash.invalid_credentials"))
    end
  end

  describe "DELETE #destroy" do
    it "signs out and returns to the store" do
      sign_in customer

      delete :destroy

      expect(controller.current_user).to be_nil
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq(I18n.t("flash.logout_successful"))
    end
  end
end
