require "rails_helper"

RSpec.describe "Admin product options", type: :system do
  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [1500, 1100]

    @admin = User.create!(name: "Admin", email: "admin-opt@example.com", password: "password123", role: :admin)
    @category = Category.create!(name: "iPhone 15 Pro Max")
    @product = Product.create!(name: "iPhone 15 Pro Max", description: "Titanium", price: 10_499, category: @category)
    @black = Color.create!(name: "Titanium black", hex: "#4b4b4b")
    @white = Color.create!(name: "Titanium white", hex: "#f2f1ee")
    @s256 = Storage.create!(value: "256GB")
    @s512 = Storage.create!(value: "512GB")
  end

  def login_as_admin
    visit "/?login=true"
    within "#login-modal" do
      fill_in "email", with: @admin.email
      fill_in "password", with: "password123"
      find(".login-modal__form button").click
    end
    expect(page).to have_current_path(admin_root_path, wait: 5)
  end

  it "lets an admin assign colors and storage prices to a product" do
    login_as_admin
    visit edit_admin_product_path(@product)

    # options section is present with the available colors and storages
    expect(page).to have_content(I18n.t("admin.products.options"))
    expect(page).to have_content("Titanium black")
    expect(page).to have_content("256GB")

    # pick a color and set prices for two storages (checkboxes are visually
    # hidden behind styled controls, so click their labels)
    check "product_color_ids_#{@black.id}", allow_label_click: true
    check "storage_enabled_#{@s256.id}", allow_label_click: true
    fill_in "product_storages[#{@s256.id}][price]", with: "10499"
    check "storage_enabled_#{@s512.id}", allow_label_click: true
    fill_in "product_storages[#{@s512.id}][price]", with: "11999"

    click_button I18n.t("admin.products.update")

    # redirected to the product show page, which now lists the options
    expect(page).to have_current_path(admin_product_path(@product), wait: 5)
    expect(page).to have_content(I18n.t("admin.products.options"))
    expect(page).to have_content("256GB")
    expect(page).to have_content("R$ 11.999,00")

    # persisted correctly
    @product.reload
    expect(@product.colors).to eq([@black])
    expect(@product.product_storages.find_by(storage: @s256).price).to eq(10_499)
    expect(@product.product_storages.find_by(storage: @s512).price).to eq(11_999)

    page.save_screenshot("tmp/admin_options.png")
  end

  it "hides the base price field once a storage variation is enabled" do
    login_as_admin
    visit new_admin_product_path

    # a product with no variations shows the editable base price
    expect(page).to have_field("product[price]")

    # enabling a storage switches pricing to the variations
    check "storage_enabled_#{@s256.id}", allow_label_click: true

    expect(page).to have_no_field("product[price]")
    expect(page).to have_content(I18n.t("admin.products.price_from_variations"))
  end
end
