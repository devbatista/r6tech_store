class Admin::Settings::NotificationsController < Admin::Settings::BaseController
  def show; end

  def update
    if @setting.update(notifications_params)
      redirect_to admin_settings_notifications_path, notice: "Notification settings updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

    def notifications_params
      params.require(:setting).permit(
        :notification_sender, :notify_on_paid, :notify_on_shipped, :notify_on_delivered
      )
    end
end
