class Admin::CategoriesController < Admin::BaseAdminController
  before_action :set_category, only: [:edit, :update, :destroy]

  def index
    per_page = params[:per].presence || 10
    @query = params[:query].to_s.strip
    categories = Category.includes(:parent).order(created_at: :desc)
    categories = search_categories(categories) if @query.present?
    @categories = categories.page(params[:page]).per(per_page)
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

    def search_categories(categories)
      term = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"

      categories
        .left_outer_joins(:parent)
        .where(
          "categories.name ILIKE :term OR parents_categories.name ILIKE :term OR CAST(categories.id AS text) ILIKE :term",
          term: term
        )
    end
end
