class Admin::Settings::StoreController < Admin::Settings::BaseController
  def show; end

  def update
    if @setting.update(store_params)
      redirect_to admin_settings_store_path, notice: "Store settings updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

    def store_params
      params.require(:setting).permit(
        :store_name, :contact_email, :contact_phone,
        :instagram_url, :facebook_url, :whatsapp,
        :timezone, :logo
      )
    end
end
