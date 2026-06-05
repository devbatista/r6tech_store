class ApplicationController < ActionController::Base
  before_action :set_locale

  helper_method :current_locale, :locale_switch_title

  private

    def set_locale
      session[:locale] = params[:locale] if available_locale?(params[:locale])
      I18n.locale = current_locale
    end

    def current_locale
      locale = session[:locale].presence || I18n.default_locale
      available_locale?(locale) ? locale.to_sym : I18n.default_locale
    end

    def locale_switch_title
      current_locale == :"pt-BR" ? "Selecionar idioma" : "Select language"
    end

    def available_locale?(locale)
      locale.present? && I18n.available_locales.map(&:to_s).include?(locale.to_s)
    end
end
