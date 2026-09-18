module Users
  class RegistrationsController < Devise::RegistrationsController
    include BaseDeviseController

    before_action :configure_sign_up_params, only: :create

    def create
      cart = guest_cart

      super do |user|
        merge_guest_cart_into(user, cart) if user.persisted?
      end
    end

    # Dados e senha são editados na página da conta, não nas telas do Devise.
    def edit
      redirect_to account_path(anchor: "details")
    end

    private

      def configure_sign_up_params
        devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
      end

      def after_sign_up_path_for(resource)
        after_sign_in_path_for(resource)
      end
  end
end
