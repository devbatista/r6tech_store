class Admin::CategoriesController < Admin::BaseAdminController
  before_action :set_category, only: [:edit, :update, :destroy]

  def index
    per_page = params[:per].presence || 10
    @categories = Category.includes(:parent).page(params[:page]).per(per_page)
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      redirect_to(admin_categories_path, notice: "Category created successfully")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @category.update(category_params)
      redirect_to(admin_categories_path, notice: "Category updated successfully")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.destroy
      redirect_to(admin_categories_path, notice: "Category deleted")
    else
      redirect_to(admin_categories_path, alert: @category.errors.full_messages.to_sentence)
    end
  end

  private

    def set_category
      @category = Category.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:name, :parent_id)
    end
end
