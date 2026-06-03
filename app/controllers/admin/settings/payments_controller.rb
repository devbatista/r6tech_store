class Admin::Settings::PaymentsController < Admin::Settings::BaseController
  def show; end

  def update
    if @setting.update(payments_params)
      redirect_to admin_settings_payments_path, notice: "Payment settings updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

    def payments_params
      params.require(:setting).permit(:pay_pix, :pay_credit_card, :pay_boleto)
    end
end
