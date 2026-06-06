require 'rails_helper'
require 'securerandom'
require 'sidekiq/testing'

RSpec.describe Admin::ProductsController, type: :controller do
  render_views

  around do |example|
    Sidekiq::Testing.fake! do
      Sidekiq::Worker.clear_all

      example.run
    ensure
      Sidekiq::Worker.clear_all
    end
  end

  describe "GET #index" do
    it "filters products by query" do
      admin = User.create!(
        name: "Admin",
        email: "admin-products-index@example.com",
        password: "password123",
        role: :admin
      )
      category = Category.create!(name: "Computers #{SecureRandom.uuid}")
      Product.create!(
        name: "Searchable MacBook",
        description: "Laptop",
        price: 12000,
        category: category
      )
      Product.create!(
        name: "Hidden iPhone",
        description: "Phone",
        price: 8000,
        category: category
      )

      session[:user_id] = admin.id

      get :index, params: { query: "MacBook" }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Searchable MacBook")
      expect(response.body).not_to include("Hidden iPhone")
    end
  end

  describe "GET #show" do
    it "renders the product detail page" do
      admin = User.create!(
        name: "Admin",
        email: "admin@example.com",
        password: "password123",
        role: :admin
      )
      category = Category.create!(name: "Phones #{SecureRandom.uuid}")
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
      expect(response.body).to include(I18n.t("admin.products.no_images"))
      expect(response.body).to include(I18n.t("admin.products.add_images"))
      expect(response.body).to include(I18n.t("admin.common.edit"))
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
      category = Category.create!(name: "Notebooks #{SecureRandom.uuid}")
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

  describe "POST #create" do
    it "enqueues AI suggestions when the product has no description or images" do
      admin = User.create!(
        name: "Admin",
        email: "admin-create-ai@example.com",
        password: "password123",
        role: :admin
      )
      category = Category.create!(name: "Phones #{SecureRandom.uuid}")
      session[:user_id] = admin.id

      expect {
        post :create, params: {
          product: {
            name: "iPhone 15",
            price: 4999.90,
            category_id: category.id
          }
        }
      }.to change(ProductAiSuggestionJob.jobs, :size).by(1)

      product = Product.order(:created_at).last
      expect(ProductAiSuggestionJob.jobs.last["args"]).to eq([product.id, false])
      expect(product.ai_description_status).to eq("pending")
      expect(product.ai_image_status).to eq("pending")
    end

    it "does not enqueue AI suggestions when description and image are present" do
      admin = User.create!(
        name: "Admin",
        email: "admin-create-complete@example.com",
        password: "password123",
        role: :admin
      )
      category = Category.create!(name: "Phones #{SecureRandom.uuid}")
      image = Rack::Test::UploadedFile.new(
        Rails.root.join("spec/fixtures/files/product-image.png"),
        "image/png"
      )
      session[:user_id] = admin.id

      expect {
        post :create, params: {
          product: {
            name: "iPhone 15",
            description: "A reliable phone.",
            price: 4999.90,
            category_id: category.id,
            images: [image]
          }
        }
      }.not_to change(ProductAiSuggestionJob.jobs, :size)
    end
  end

  describe "managing color and storage options" do
    let(:admin) do
      User.create!(name: "Admin", email: "admin-options-#{SecureRandom.uuid}@example.com",
                   password: "password123", role: :admin)
    end
    let(:category) { Category.create!(name: "Phones #{SecureRandom.uuid}") }
    let(:black) { Color.create!(name: "Titanium black", hex: "#4b4b4b") }
    let(:white) { Color.create!(name: "Titanium white", hex: "#f2f1ee") }
    let(:s256) { Storage.create!(value: "256GB") }
    let(:s512) { Storage.create!(value: "512GB") }

    before { session[:user_id] = admin.id }

    it "creates a product with chosen colors and storage prices" do
      post :create, params: {
        product: {
          name: "iPhone 15 Pro Max", description: "Titanium", price: 10_499,
          category_id: category.id, color_ids: [black.id, white.id]
        },
        product_storages: {
          s256.id => { enabled: "1", price: "10499" },
          s512.id => { enabled: "1", price: "11999" }
        }
      }

      product = Product.order(:created_at).last
      expect(product.colors).to match_array([black, white])
      expect(product.product_storages.find_by(storage: s256).price).to eq(10_499)
      expect(product.product_storages.find_by(storage: s512).price).to eq(11_999)
    end

    it "ignores storages that are not enabled" do
      post :create, params: {
        product: { name: "iPhone 15", price: 7000, category_id: category.id },
        product_storages: {
          s256.id => { enabled: "1", price: "7000" },
          s512.id => { enabled: "0", price: "8000" }
        }
      }

      product = Product.order(:created_at).last
      expect(product.storages).to eq([s256])
    end

    it "adds, reprices and removes storages on update" do
      product = Product.create!(name: "iPhone 15", price: 7000, category: category)
      ProductColor.create!(product: product, color: black)
      ProductStorage.create!(product: product, storage: s256, price: 7000)

      patch :update, params: {
        id: product.id,
        product: { name: "iPhone 15", price: 7000, category_id: category.id, color_ids: [white.id] },
        product_storages: {
          s256.id => { enabled: "0", price: "7000" },   # remove
          s512.id => { enabled: "1", price: "9000" }    # add
        }
      }

      product.reload
      expect(product.colors).to eq([white])
      expect(product.storages).to eq([s512])
      expect(product.product_storages.find_by(storage: s512).price).to eq(9000)
    end

    it "derives the base price from the cheapest variation when storages exist" do
      post :create, params: {
        product: { name: "iPhone 15 Pro Max", category_id: category.id },
        product_storages: {
          s256.id => { enabled: "1", price: "11999" },
          s512.id => { enabled: "1", price: "10499" }
        }
      }

      product = Product.order(:created_at).last
      expect(product.price).to eq(10_499)
    end

    it "keeps the base price for products without variations" do
      post :create, params: {
        product: { name: "AirPods Pro 2", price: 2500, category_id: category.id },
        product_storages: {}
      }

      product = Product.order(:created_at).last
      expect(product.price).to eq(2500)
      expect(product.product_storages).to be_empty
    end

    it "re-derives the base price when variation prices change on update" do
      product = Product.create!(name: "iPhone 15", price: 10_499, category: category)
      ProductStorage.create!(product: product, storage: s256, price: 10_499)

      patch :update, params: {
        id: product.id,
        product: { name: "iPhone 15", category_id: category.id },
        product_storages: {
          s256.id => { enabled: "1", price: "9999" },
          s512.id => { enabled: "1", price: "12999" }
        }
      }

      expect(product.reload.price).to eq(9_999)
    end

    it "renders the options section with colors and storages on the edit form" do
      black; white; s256; s512
      product = Product.create!(name: "iPhone 15", price: 7000, category: category)

      get :edit, params: { id: product.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("admin.products.options"))
      expect(response.body).to include("Titanium black")
      expect(response.body).to include("256GB")
      expect(response.body).to include("product_storages[#{s512.id}][price]")
    end
  end

  describe "PATCH #approve_ai_description" do
    it "copies the suggested description to the product description" do
      admin = User.create!(
        name: "Admin",
        email: "admin-approve-description@example.com",
        password: "password123",
        role: :admin
      )
      category = Category.create!(name: "Phones #{SecureRandom.uuid}")
      product = Product.create!(
        name: "iPhone 15",
        ai_description: "Descricao aprovada.",
        ai_description_status: "ready",
        price: 4999.90,
        category: category
      )
      session[:user_id] = admin.id

      patch :approve_ai_description, params: { id: product.id }

      expect(response).to redirect_to(admin_product_path(product))
      expect(product.reload.description).to eq("Descricao aprovada.")
      expect(product.ai_description_status).to eq("approved")
    end
  end

  describe "PATCH #approve_ai_image" do
    it "attaches the suggested image to storefront images" do
      admin = User.create!(
        name: "Admin",
        email: "admin-approve-image@example.com",
        password: "password123",
        role: :admin
      )
      category = Category.create!(name: "Phones #{SecureRandom.uuid}")
      product = Product.create!(
        name: "iPhone 15",
        description: "A reliable phone.",
        ai_image_status: "ready",
        price: 4999.90,
        category: category
      )
      product.ai_generated_images.attach(
        io: StringIO.new("fake image"),
        filename: "generated.png",
        content_type: "image/png"
      )
      session[:user_id] = admin.id

      patch :approve_ai_image, params: { id: product.id }

      product.reload
      expect(response).to redirect_to(admin_product_path(product))
      expect(product.images).to be_attached
      expect(product.ai_generated_images).not_to be_attached
      expect(product.ai_image_status).to eq("approved")
    end
  end

  describe "GET #show with AI suggestions" do
    it "renders generated suggestion controls" do
      admin = User.create!(
        name: "Admin",
        email: "admin-show-ai@example.com",
        password: "password123",
        role: :admin
      )
      category = Category.create!(name: "Phones #{SecureRandom.uuid}")
      product = Product.create!(
        name: "iPhone 15",
        ai_description: "Descricao sugerida.",
        ai_description_status: "ready",
        ai_image_status: "failed",
        ai_error: "Provider unavailable",
        price: 4999.90,
        category: category
      )
      session[:user_id] = admin.id

      get :show, params: { id: product.id }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("admin.products.ai_suggestions"))
      expect(response.body).to include("Descricao sugerida.")
      expect(response.body).to include(I18n.t("admin.products.approve_description"))
      expect(response.body).to include("Provider unavailable")
      expect(response.body).to include(I18n.t("admin.products.generate_again"))
    end
  end
end
