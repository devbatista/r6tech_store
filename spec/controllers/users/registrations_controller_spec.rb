require "rails_helper"

RSpec.describe Users::RegistrationsController, type: :controller do
  render_views

  let!(:category) { Category.create!(name: "Accessories") }
  let!(:product) { Product.create!(name: "USB Cable", price: 20, category: category) }

  before { @request.env["devise.mapping"] = Devise.mappings[:user] }

  describe "GET #new" do
    it "renders the sign up page in the storefront layout" do
      get :new

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("storefront.auth.sign_up_title"))
      expect(response.body).to include("storefront-body")
    end
  end

  describe "POST #create" do
    let(:params) do
      { user: { name: "New Customer", email: "new@example.com", password: "password", password_confirmation: "password" } }
    end

    it "creates a customer, signs them in and merges the guest cart" do
      guest_cart = Cart.create!(status: :active)
      guest_cart.cart_items.create!(product: product, quantity: 1)
      session[:cart_id] = guest_cart.id

      expect { post :create, params: params }.to change(User, :count).by(1)

      user = User.find_by!(email: "new@example.com")
      expect(user).to be_customer
      expect(user.name).to eq("New Customer")
      expect(controller.current_user).to eq(user)
      expect(response).to redirect_to(root_path)
      expect(session[:cart_id]).to be_nil
      expect(user.carts.find_by(status: :active).cart_items.sum(:quantity)).to eq(1)
    end

    it "does not allow choosing the role" do
      post :create, params: { user: params[:user].merge(role: "admin") }

      expect(User.find_by!(email: "new@example.com")).to be_customer
    end

    it "re-renders the form with errors when data is invalid" do
      post :create, params: { user: params[:user].merge(password_confirmation: "other") }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("auth-form__errors")
      expect(controller.current_user).to be_nil
    end
  end

  describe "GET #edit" do
    it "sends signed-in users to the account page" do
      sign_in User.create!(name: "Customer", email: "customer@example.com", password: "password")

      get :edit

      expect(response).to redirect_to(account_path(anchor: "details"))
    end
  end
end
