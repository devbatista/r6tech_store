require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe "GET #index" do
    it "renews the session when the signed-in user no longer exists" do
      session[:user_id] = SecureRandom.uuid

      get :index

      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(login_path)
      expect(flash[:alert]).to eq("Your session expired. Please sign in again.")
    end
  end
end
