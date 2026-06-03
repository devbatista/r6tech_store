class Admin::Settings::AppearanceController < Admin::Settings::BaseController
  def show; end

  def update
    if @setting.update(appearance_params)
      redirect_to admin_settings_appearance_path, notice: "Appearance settings updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

    def appearance_params
      params.require(:setting).permit(:default_dark_mode)
    end
end
