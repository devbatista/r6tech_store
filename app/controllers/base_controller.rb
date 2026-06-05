class BaseController < ApplicationController
  before_action :renew_session_if_user_was_removed

  helper_method :current_user

  private

    def current_user
      @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
    end

    def authorize_admin!
      unless current_user&.admin?
        redirect_to login_path, alert: t("flash.access_restricted")
      end
    end

    def renew_session_if_user_was_removed
      return unless session[:user_id]
      return if current_user

      reset_session
      redirect_to login_path, alert: t("flash.session_expired")
    end
end
