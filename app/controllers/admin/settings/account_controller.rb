class Admin::Settings::AccountController < Admin::Settings::BaseController
  def show
    @account = current_user
  end

  def update
    @account = current_user
    if @account.update(account_params)
      redirect_to admin_settings_account_path, notice: "Account updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

    def account_params
      permitted = params.require(:user).permit(:name, :email, :phone, :password, :password_confirmation)
      # Senha em branco = não alterar a senha atual.
      if permitted[:password].blank?
        permitted.delete(:password)
        permitted.delete(:password_confirmation)
      end
      permitted
    end
end
