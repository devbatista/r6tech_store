class OrdersController < BaseController
  before_action :require_customer!
  before_action :set_order, only: [:show, :cancel, :pay, :payment_return]

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

  # Leva o cliente ao Checkout Pro (primeira vez ou nova tentativa após recusa).
  def pay
    unless @order.payment&.payable?
      return redirect_to order_path(@order), alert: t("storefront.payment.not_payable")
    end

    redirect_to Payments::Checkout.call(payment: @order.payment), allow_other_host: true
  rescue Payments::Error => error
    Rails.logger.error("[payments] checkout failed for order #{@order.id}: #{error.message}")
    redirect_to order_path(@order), alert: t("storefront.payment.checkout_unavailable")
  end

  # back_url do Mercado Pago. Os parâmetros da query não são confiáveis; o status
  # é consultado na API pelo id do pagamento e o webhook cobre o que chegar depois.
  def payment_return
    provider_payment_id = params[:payment_id].presence || params[:collection_id].presence

    if provider_payment_id.present?
      Payments::Sync.call(provider_payment_id: provider_payment_id)
      @order.reload
    end

    redirect_to order_path(@order), notice: t("storefront.payment.return_notice.#{@order.payment&.status || "awaiting_payment"}")
  rescue Payments::Error => error
    Rails.logger.error("[payments] return sync failed for order #{@order.id}: #{error.message}")
    redirect_to order_path(@order), notice: t("storefront.payment.return_notice.awaiting_payment")
  end

  private

    def require_customer!
      return if current_user&.customer?

      require_sign_in!(return_to: cart_path, alert: t("store.auth.sign_in_to_checkout"))
    end

    def set_order
      @order = current_user.orders.find(params[:id])
    end
end
