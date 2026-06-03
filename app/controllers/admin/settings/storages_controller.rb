class Admin::Settings::StoragesController < Admin::Settings::BaseController
  before_action :set_storage, only: [:edit, :update, :destroy]

  def index
    @storages = Storage.all
  end

  def new
    @storage = Storage.new
  end

  def create
    @storage = Storage.new(storage_params)
    if @storage.save
      redirect_to admin_settings_storages_path, notice: "Storage created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @storage.update(storage_params)
      redirect_to admin_settings_storages_path, notice: "Storage updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @storage.destroy
    redirect_to admin_settings_storages_path, notice: "Storage removed."
  end

  private

    def set_storage
      @storage = Storage.find(params[:id])
    end

    def storage_params
      params.require(:storage).permit(:value)
    end
end
