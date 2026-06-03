class Admin::Settings::AdministratorsController < Admin::Settings::BaseController
  before_action :set_administrator, only: [:edit, :update, :destroy]

  def index
    @administrators = User.where(role: :admin).order(:name)
  end

  def new
    @administrator = User.new(role: :admin)
  end

  def create
    @administrator = User.new(administrator_params.merge(role: :admin))
    if @administrator.save
      redirect_to admin_settings_administrators_path, notice: "Administrator created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @administrator.update(administrator_params)
      redirect_to admin_settings_administrators_path, notice: "Administrator updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @administrator == current_user
      redirect_to admin_settings_administrators_path, alert: "You can't remove your own account."
    elsif User.where(role: :admin).count <= 1
      redirect_to admin_settings_administrators_path, alert: "There must be at least one administrator."
    else
      @administrator.destroy
      redirect_to admin_settings_administrators_path, notice: "Administrator removed."
    end
  end

  private

    def set_administrator
      @administrator = User.where(role: :admin).find(params[:id])
    end

    def administrator_params
      permitted = params.require(:user).permit(:name, :email, :phone, :password, :password_confirmation)
      # Senha em branco na edição = manter a atual.
      if permitted[:password].blank?
        permitted.delete(:password)
        permitted.delete(:password_confirmation)
      end
      permitted
    end
end
