class PaymentsController < BaseController
  helper_method :payment_params_selected_shipping_id
  before_action :require_customer!
  before_action :load_checkout

  def new
    return redirect_to(cart_path, alert: t("flash.cart_empty")) if @cart.cart_items.empty?

    @payment = Payment.new
  end

  def create
    selected_method = payment_params[:payment_method]
    @payment = Payment.new
    @payment.payment_method = selected_method if Payment.payment_methods.key?(selected_method)

    unless enabled_payment_methods.include?(selected_method)
      @payment.errors.add(:payment_method, t("storefront.payment.invalid_method"))
      return render :new, status: :unprocessable_entity
    end

    address = current_user.addresses.find_by(id: payment_params[:address_id])
    unless address
      @payment.errors.add(:base, t("storefront.shipping.address_required"))
      return render :new, status: :unprocessable_entity
    end

    shipping_quote = selected_shipping_quote(address)
    unless shipping_quote
      @payment.errors.add(:base, t("storefront.shipping.option_required"))
      return render :new, status: :unprocessable_entity
    end

    order = Order.transaction do
      created_order = Order.create_from_cart!(
        user: current_user,
        cart: @cart,
        setting: @setting,
        shipping_address: address,
        shipping_quote: shipping_quote
      )
      created_order.create_payment!(
        payment_method: @payment.payment_method,
        amount: created_order.total,
        status: :awaiting_payment,
        metadata: payment_metadata
      )
      created_order
    end

    redirect_to order_path(order), notice: t("storefront.payment.order_created")
  rescue Shipping::Error => error
    @payment.errors.add(:base, error.message)
    render :new, status: :unprocessable_entity
  end

  private

    def require_customer!
      return if current_user&.customer?

      session[:return_to] = new_payment_path
      redirect_to login_path, alert: t("store.auth.sign_in_to_checkout")
    end

    def load_checkout
      @cart = current_cart
      @setting = Setting.instance
      @enabled_payment_methods = enabled_payment_methods
      @addresses = current_user.addresses.order(default: :desc, created_at: :asc)
      @selected_address = selected_address
      @shipping_quotes = shipping_quotes_for(@selected_address)
    rescue Shipping::Error => error
      @shipping_error = error.message
      @shipping_quotes = []
    end

    def enabled_payment_methods
      methods = []
      methods << "pix" if @setting.pay_pix?
      methods << "credit_card" if @setting.pay_credit_card?
      methods << "boleto" if @setting.pay_boleto?
      methods
    end

    def payment_params
      params.require(:payment).permit(:payment_method, :installments, :address_id, :shipping_service_id)
    end

    def payment_metadata
      return {} unless @payment.credit_card?

      installments = payment_params[:installments].to_i.clamp(1, 12)
      { installments: installments }
    end

    def selected_address
      address_id = params.dig(:payment, :address_id) || params[:address_id]
      current_user.addresses.find_by(id: address_id) || @addresses.first
    end

    def shipping_quotes_for(address)
      return [] unless address

      Shipping::CheckoutQuotes.call(
        cart: @cart,
        destination_postal_code: address.zip_code,
        setting: @setting
      )
    end

    def selected_shipping_quote(address)
      service_id = payment_params[:shipping_service_id].to_s
      shipping_quotes_for(address).find { |quote| quote[:service_id].to_s == service_id }
    end

    def payment_params_selected_shipping_id
      params.dig(:payment, :shipping_service_id).to_s
    end
end
