class Admin::Settings::ShippingController < Admin::Settings::BaseController
  def show; end

  def update
    if @setting.update(shipping_params)
      redirect_to admin_settings_shipping_path, notice: "Shipping & order settings updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

    def shipping_params
      params.require(:setting).permit(
        :shipping_fee, :free_shipping_threshold, :tax_rate, :default_order_status
      )
    end
end
