require "rails_helper"

RSpec.describe "Payment form", type: :system do
  before do
    driven_by :selenium, using: :headless_chrome, screen_size: [1400, 900]

    category = Category.create!(name: "Accessories")
    @product = Product.create!(name: "USB Cable", price: 20, category: category)
    @user = User.create!(name: "Customer", email: "payment-form@example.com", password: "password123")
    @user.addresses.create!(
      recipient: @user.name,
      zip_code: "01310-100",
      street: "Avenida Paulista",
      number: "1000",
      city: "Sao Paulo",
      state: "SP",
      default: true
    )
    Setting.instance.update!(pay_pix: true, pay_credit_card: true, shipping_fee: 12.5)
  end

  it "shows the enabled methods without collecting card data and updates the total with shipping" do
    visit root_path(login: true)
    within "#login-modal" do
      fill_in "user[email]", with: @user.email
      fill_in "user[password]", with: "password123"
      click_button I18n.t("storefront.auth.login")
    end

    visit product_path(@product)
    click_button I18n.t("storefront.cart.add")
    visit new_payment_path

    expect(page).to have_field("payment[payment_method]", with: "pix", visible: :all)
    expect(page).to have_field("payment[payment_method]", with: "credit_card", visible: :all)
    expect(page).not_to have_css("input[autocomplete^='cc-']", visible: :all)
    expect(page).to have_text(I18n.t("storefront.payment.integration_notice"))

    within ".cart-summary" do
      expect(page).to have_text("R$ 32,50")
    end

    expect(page).to have_button(I18n.t("storefront.payment.go_to_checkout"))
  end
end
