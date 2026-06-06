class AddressesController < BaseController
  before_action :require_customer!
  before_action :set_address, only: [:update, :destroy]

  def create
    address = current_user.addresses.new(address_params)

    if address.save
      redirect_to account_path(anchor: "addresses"), notice: t("flash.address_created")
    else
      redirect_to account_path(new_address: 1, anchor: "addresses"), alert: address.errors.full_messages.to_sentence
    end
  end

  def update
    if @address.update(address_params)
      redirect_to account_path(anchor: "addresses"), notice: t("flash.address_updated")
    else
      redirect_to account_path(address_id: @address.id, anchor: "addresses"), alert: @address.errors.full_messages.to_sentence
    end
  end

  def destroy
    @address.destroy!
    redirect_to account_path(anchor: "addresses"), notice: t("flash.address_deleted")
  end

  private

    def require_customer!
      return if current_user&.customer?

      redirect_to login_path, alert: t("storefront.auth.sign_in_to_account")
    end

    def set_address
      @address = current_user.addresses.find(params[:id])
    end

    def address_params
      params.require(:address).permit(:label, :recipient, :zip_code, :street, :number, :complement, :neighborhood, :city, :state, :country, :default)
    end
end
