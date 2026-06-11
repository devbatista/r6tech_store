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

  describe "POST #create" do
    it "attaches an uploaded image to the category" do
      admin = User.create!(
        name: "Admin",
        email: "admin-categories-create@example.com",
        password: "password123",
        role: :admin
      )
      image = Rack::Test::UploadedFile.new(
        Rails.root.join("spec/fixtures/files/product-image.png"),
        "image/png"
      )
      session[:user_id] = admin.id

      post :create, params: { category: { name: "Category with image", image: image } }

      expect(response).to redirect_to(admin_categories_path)
      expect(Category.find_by!(name: "Category with image").image).to be_attached
    end

    it "ignores a parent category assignment" do
      admin = User.create!(
        name: "Admin",
        email: "admin-categories-parent@example.com",
        password: "password123",
        role: :admin
      )
      parent = Category.create!(name: "Parent category")
      session[:user_id] = admin.id

      post :create, params: { category: { name: "Root category", parent_id: parent.id } }

      expect(Category.find_by!(name: "Root category").parent_id).to be_nil
    end
  end

  describe "PATCH #update" do
    it "removes the attached category image" do
      admin = User.create!(
        name: "Admin",
        email: "admin-categories-update@example.com",
        password: "password123",
        role: :admin
      )
      category = Category.create!(name: "Category with removable image")
      category.image.attach(
        io: File.open(Rails.root.join("spec/fixtures/files/product-image.png")),
        filename: "category-image.png",
        content_type: "image/png"
      )
      session[:user_id] = admin.id

      patch :update, params: {
        id: category.id,
        category: { name: category.name, remove_image: "1" }
      }

      expect(response).to redirect_to(admin_categories_path)
      expect(category.reload.image).not_to be_attached
    end
  end
end
