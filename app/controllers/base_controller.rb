class BaseController < ApplicationController
  include CurrentCart

  layout "storefront"

  private

    def authorize_admin!
      unless current_user&.admin?
        redirect_to new_user_session_path, alert: t("flash.access_restricted")
      end
    end

    # Guarda o destino para o Devise redirecionar depois do login.
    def require_sign_in!(return_to:, alert:)
      store_location_for(:user, return_to)
      redirect_to new_user_session_path, alert: alert
    end
end
