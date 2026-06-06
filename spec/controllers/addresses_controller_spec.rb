require "rails_helper"

RSpec.describe AddressesController, type: :controller do
  let!(:user) { User.create!(name: "Customer", email: "address-customer@example.com", password: "password") }
  let!(:address) { user.addresses.create!(label: "Casa", recipient: user.name, zip_code: "01310-100", street: "Avenida Paulista", city: "São Paulo", state: "SP") }

  before { session[:user_id] = user.id }

  it "creates an address for the current customer" do
    expect {
      post :create, params: { address: { label: "Trabalho", recipient: user.name, zip_code: "04543-011", street: "Faria Lima", city: "São Paulo", state: "SP" } }
    }.to change(user.addresses, :count).by(1)

    expect(response).to redirect_to(account_path(anchor: "addresses"))
  end

  it "updates the current customer's address" do
    patch :update, params: { id: address.id, address: { label: "Principal" } }

    expect(address.reload.label).to eq("Principal")
  end

  it "deletes the current customer's address" do
    expect { delete :destroy, params: { id: address.id } }.to change(user.addresses, :count).by(-1)
  end

  it "does not update another customer's address" do
    other = User.create!(name: "Other", email: "other-address@example.com", password: "password")
    other_address = other.addresses.create!(zip_code: "00000-000", street: "Other", city: "Other", state: "OT")

    expect {
      patch :update, params: { id: other_address.id, address: { city: "Changed" } }
    }.to raise_error(ActiveRecord::RecordNotFound)
  end
end
