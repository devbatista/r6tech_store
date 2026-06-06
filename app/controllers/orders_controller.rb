class OrdersController < BaseController
  before_action :require_customer!
  before_action :set_order, only: [:show, :cancel]

  def index
    @orders = current_user.orders
  end

  def show;end

  def create
    cart = current_cart
    
    if cart && cart.cart_items.any?
      order = Order.transaction do
        total = cart.total_with_shipping
        created_order = current_user.orders.create!(status: :pending, total: total)

        cart.cart_items.each do |item|
          created_order.order_items.create!(
            product: item.product,
            quantity: item.quantity,
            price: item.product.price
          )
        end

        cart.update!(status: :ordered)
        created_order
      end
      redirect_to order_path(order), notice: t("flash.order_placed")
    else
      redirect_to cart_path, alert: t("flash.cart_empty")
    end
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
