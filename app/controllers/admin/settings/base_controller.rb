class Admin::Settings::BaseController < Admin::BaseAdminController
  before_action :set_setting

  private

    def set_setting
      @setting = Setting.instance
    end
end
