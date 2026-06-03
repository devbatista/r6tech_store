class Admin::Settings::ColorsController < Admin::Settings::BaseController
  before_action :set_color, only: [:edit, :update, :destroy]

  def index
    @colors = Color.order(:name)
  end

  def new
    @color = Color.new
  end

  def create
    @color = Color.new(color_params)
    if @color.save
      redirect_to admin_settings_colors_path, notice: "Color created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @color.update(color_params)
      redirect_to admin_settings_colors_path, notice: "Color updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @color.destroy
    redirect_to admin_settings_colors_path, notice: "Color removed."
  end

  private

    def set_color
      @color = Color.find(params[:id])
    end

    def color_params
      params.require(:color).permit(:name, :hex)
    end
end
