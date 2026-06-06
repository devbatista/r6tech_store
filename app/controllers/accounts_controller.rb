class AccountsController < BaseController
  before_action :require_customer!

  def show
    @orders = current_user.orders.includes(order_items: :product).order(created_at: :desc)
    @selected_order = @orders.find_by(id: params[:order_id])
    @addresses = current_user.addresses.order(default: :desc, created_at: :asc)
    @selected_address = current_user.addresses.find_by(id: params[:address_id])
    @selected_address ||= current_user.addresses.new(default: @addresses.none?) if params[:new_address].present?
  end

  def update
    if password_change_requested?
      update_password
    else
      update_profile
    end
  end

  private

    def update_profile
      if current_user.update(profile_params)
        redirect_to account_path(anchor: "details"), notice: t("flash.account_updated")
      else
        redirect_to account_path(anchor: "details"), alert: current_user.errors.full_messages.to_sentence
      end
    end

    def update_password
      if current_user.update_with_password(password_params)
        session[:user_id] = current_user.id
        redirect_to account_path(anchor: "details"), notice: t("flash.password_updated")
      else
        redirect_to account_path(anchor: "details"), alert: current_user.errors.full_messages.to_sentence
      end
    end

    def password_change_requested?
      params.dig(:user, :password).present?
    end

    def profile_params
      params.require(:user).permit(:name, :email)
    end

    def password_params
      params.require(:user).permit(:current_password, :password, :password_confirmation)
    end

    def require_customer!
      return if current_user&.customer?

      session[:return_to] = account_path
      redirect_to login_path, alert: t("storefront.auth.sign_in_to_account")
    end
end
