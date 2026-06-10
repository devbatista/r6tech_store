class OrdersController < BaseController
  before_action :require_customer!
  before_action :set_order, only: [:show, :cancel]

  def index
    @orders = current_user.orders
  end

  def show;end

  def create
    redirect_to new_payment_path
  end

  def cancel
    if @order.pending?
      @order.update(status: :cancelled)
      redirect_to orders_path, notice: t("flash.order_cancelled")
    else
      redirect_to order_path(@order), alert: t("flash.order_cannot_be_cancelled")
    end
  end

  private

    def require_customer!
      return if current_user&.customer?

      session[:return_to] = cart_path
      redirect_to login_path, alert: t("store.auth.sign_in_to_checkout")
    end

    def set_order
      @order = current_user.orders.find(params[:id])
    end
end
