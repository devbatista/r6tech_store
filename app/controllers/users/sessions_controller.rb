module Users
  class SessionsController < Devise::SessionsController
    include BaseDeviseController

    # O login acontece no modal da home; a rota GET só existe para os redirects do Devise.
    def new
      flash.keep
      redirect_to root_path(anchor: "login-modal")
    end

    # Autentica via Warden sem lançar exceção, para tratar a falha aqui mesmo:
    # volta para a home com o modal aberto e o e-mail preenchido, como antes.
    def create
      cart = guest_cart
      self.resource = warden.authenticate(auth_options)

      if resource
        sign_in(resource_name, resource)
        merge_guest_cart_into(resource, cart)
        redirect_to after_sign_in_path_for(resource), notice: t("flash.login_successful")
      else
        redirect_to root_path(email: sign_in_params[:email], anchor: "login-modal"), alert: t("flash.invalid_credentials")
      end
    end

    private

      def after_sign_out_path_for(_resource_or_scope)
        root_path
      end

      # Devise não deixa reaproveitar o flash padrão de logout junto com uma mensagem própria,
      # então substituímos a dele pela chave já traduzida do projeto.
      def respond_to_on_destroy
        redirect_to after_sign_out_path_for(resource_name), notice: t("flash.logout_successful"), status: :see_other
      end
  end
end
