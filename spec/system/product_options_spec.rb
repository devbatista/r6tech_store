require "rails_helper"

RSpec.describe "Product options", type: :system do
  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 900]

    category = Category.create!(name: "iPhone 15 Pro Max")
    @product = Product.create!(name: "iPhone 15 Pro Max", price: 10_499, category: category)

    @black = Color.create!(name: "Titanium black", hex: "#4b4b4b")
    @white = Color.create!(name: "Titanium white", hex: "#f2f1ee")
    ProductColor.create!(product: @product, color: @black)
    ProductColor.create!(product: @product, color: @white)

    s256 = Storage.create!(value: "256GB")
    s512 = Storage.create!(value: "512GB")
    ProductStorage.create!(product: @product, storage: s256, price: 10_499)
    ProductStorage.create!(product: @product, storage: s512, price: 11_999)
  end

  it "shows color and storage options and updates the price" do
    visit product_path(@product)

    # color swatches and storage pills are rendered
    expect(page).to have_css(".swatch", count: 2)
    expect(page).to have_css(".storage-pill", count: 2)

    # the color label matches the swatch that is actually selected by default
    checked_swatch = find(".swatch input:checked", visible: :all)
    selected_color_name = checked_swatch.find(:xpath, "..")[:title]
    expect(find("[data-product-options-target='colorName']")).to have_text(selected_color_name)

    # the cheapest storage is selected by default and drives the displayed price
    expect(find(".product-info__price")).to have_text("10.499,00")

    # picking the larger storage updates the price live (no reload)
    find("label.storage-pill", text: "512GB").click
    expect(find(".product-info__price")).to have_text("11.999,00")
  end

  it "adds the chosen variant to the cart and shows it in the drawer" do
    visit product_path(@product)

    find(".swatch[title='Titanium black']").click
    find("label.storage-pill", text: "512GB").click
    click_button I18n.t("storefront.cart.add")

    # drawer opens with the selected variant and its storage-based price
    expect(page).to have_css("#cart-drawer.is-open")
    within "#cart-drawer" do
      expect(page).to have_content("iPhone 15 Pro Max")
      expect(page).to have_content("Titanium black · 512GB")
      expect(page).to have_content("R$ 11.999,00")
    end
    expect(find("#cart_count")).to have_text("1")
    expect(page).to have_current_path(product_path(@product))
  end

  it "blocks quick-add from the listing and links to the product page instead" do
    visit products_path

    # products with options show a link to choose options, not a quick-add button
    expect(page).to have_css("a.product-card__add")
    expect(page).not_to have_css("form .product-card__add")
  end
end
