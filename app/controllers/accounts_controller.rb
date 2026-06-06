class AccountsController < BaseController
  before_action :require_customer!

  def show
    @orders = current_user.orders.includes(order_items: :product).order(created_at: :desc)
    @selected_order = @orders.find_by(id: params[:order_id])
    @addresses = current_user.addresses.order(default: :desc, created_at: :asc)
    @selected_address = current_user.addresses.find_by(id: params[:address_id])
    @selected_address ||= current_user.addresses.new(default: @addresses.none?) if params[:new_address].present?
  end

  private

    def require_customer!
      return if current_user&.customer?

      session[:return_to] = account_path
      redirect_to login_path, alert: t("storefront.auth.sign_in_to_account")
    end
end
