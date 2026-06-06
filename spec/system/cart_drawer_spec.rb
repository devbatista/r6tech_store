require "rails_helper"

RSpec.describe "Cart drawer", type: :system do
  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 900]
  end

  it "opens the side drawer when clicking the cart link" do
    visit root_path
    expect(page).not_to have_css("#cart-drawer.is-open")

    find(".header-cart").click

    expect(page).to have_css("#cart-drawer.is-open")
    expect(page).to have_css(".cart-drawer__panel", visible: true)
    # opens as an overlay, without navigating to the full cart page
    expect(page).to have_current_path(root_path)

    # the panel slides in as a fixed overlay anchored to the right edge
    overlay_position = page.evaluate_script("getComputedStyle(document.getElementById('cart-drawer')).position")
    panel_right = page.evaluate_script("getComputedStyle(document.querySelector('.cart-drawer__panel')).right")
    expect(overlay_position).to eq("fixed")
    expect(panel_right).to eq("0px")
  end

  it "opens the drawer with the product after adding it to the cart" do
    category = Category.create!(name: "Acessórios")
    product = Product.create!(name: "Carregador MagSafe", price: 199.90, category: category)

    visit products_path
    find(".product-card__add").click

    # drawer slides open via Turbo Stream + open_cart action, no full navigation
    expect(page).to have_css("#cart-drawer.is-open")
    within "#cart-drawer" do
      expect(page).to have_content(product.name)
      expect(page).to have_content("R$ 199,90")
      expect(page).to have_button(I18n.t("storefront.cart.checkout"))
    end
    # header badge reflects the new item count
    expect(find("#cart_count")).to have_text("1")
    expect(page).to have_current_path(products_path)
  end

  it "closes when pressing escape" do
    visit root_path
    find(".header-cart").click
    expect(page).to have_css("#cart-drawer.is-open")

    find("body").send_keys(:escape)
    expect(page).not_to have_css("#cart-drawer.is-open")
  end
end
