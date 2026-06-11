class Admin::CategoriesController < Admin::BaseAdminController
  before_action :set_category, only: [:edit, :update, :destroy]

  def index
    per_page = params[:per].presence || 10
    @query = params[:query].to_s.strip
    categories = Category.with_attached_image.order(created_at: :desc)
    categories = search_categories(categories) if @query.present?
    @categories = categories.page(params[:page]).per(per_page)
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    if @category.save
      redirect_to(admin_categories_path, notice: t("flash.category_created"))
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    attributes = category_params
    remove_image = ActiveModel::Type::Boolean.new.cast(attributes.delete(:remove_image))

    if @category.update(attributes)
      @category.image.purge if remove_image && attributes[:image].blank?
      redirect_to(admin_categories_path, notice: t("flash.category_updated"))
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @category.destroy
      redirect_to(admin_categories_path, notice: t("flash.category_deleted"))
    else
      redirect_to(admin_categories_path, alert: @category.errors.full_messages.to_sentence)
    end
  end

  private

    def set_category
      @category = Category.find(params[:id])
    end

    def category_params
      params.require(:category).permit(:name, :image, :remove_image)
    end

    def search_categories(categories)
      term = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"

      categories.where(
        "categories.name ILIKE :term OR CAST(categories.id AS text) ILIKE :term",
        term: term
      )
    end
end
