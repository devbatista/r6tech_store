require 'rails_helper'

RSpec.describe CartsController, type: :controller do
  it "shows a cart to a visitor" do
    get :show

    expect(response).to have_http_status(:ok)
    cart = controller.instance_variable_get(:@cart)
    expect(cart).to be_active
    expect(cart.user).to be_nil
  end
end
