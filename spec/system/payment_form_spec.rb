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
    Setting.instance.update!(pay_pix: true, pay_credit_card: true)
  end

  it "reveals and formats card fields without submitting sensitive values" do
    visit root_path(login: true)
    within "#login-modal" do
      fill_in "email", with: @user.email
      fill_in "password", with: "password123"
      click_button I18n.t("storefront.auth.login")
    end

    visit product_path(@product)
    click_button I18n.t("storefront.cart.add")
    visit new_payment_path
    expect(page).to have_css(".payment-card-fields", visible: :hidden)

    find("input[value='credit_card']", visible: :all).choose
    expect(page).to have_css(".payment-card-fields", visible: :visible)

    card_number = find("input[autocomplete='cc-number']")
    card_number.set("4111111111111111")

    expect(card_number.value).to eq("4111 1111 1111 1111")
    expect(page).to have_text("Visa")
    expect(card_number[:name]).to be_blank
    expect(find("input[autocomplete='cc-csc']")[:name]).to be_blank
  end
end
