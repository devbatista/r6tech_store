class Admin::ProductsController < Admin::BaseAdminController
  before_action :set_product, only: [
    :show,
    :edit,
    :update,
    :destroy,
    :generate_ai_suggestions,
    :approve_ai_description,
    :approve_ai_image
  ]

  def index
    per_page = params[:per].presence || 10
    @query = params[:query].to_s.strip
    products = Product.includes(:category).order(created_at: :desc)
    products = search_products(products) if @query.present?
    @products = products.page(params[:page]).per(per_page)
  end

  def show;end

  def new
    @product = Product.new  
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      enqueue_ai_suggestions(@product) if @product.needs_ai_suggestions?
      redirect_to(admin_product_path(@product), notice: t("flash.product_created"))
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit;end

  def update
    if @product.update(product_params)
      redirect_to(admin_product_path(@product), notice: t("flash.product_updated"))
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @product.destroy
      redirect_to(admin_products_path, notice: t("flash.product_removed"), status: :see_other)
    else
      redirect_to(admin_products_path, alert: @product.errors.full_messages, status: :see_other)
    end
  end

  def generate_ai_suggestions
    enqueue_ai_suggestions(@product, force: true)
    redirect_to(admin_product_path(@product), notice: t("flash.ai_suggestions_generating"))
  end

  def approve_ai_description
    if @product.ai_description.present?
      @product.update!(description: @product.ai_description, ai_description_status: "approved", ai_error: nil)
      redirect_to(admin_product_path(@product), notice: t("flash.ai_description_approved"))
    else
      redirect_to(admin_product_path(@product), alert: t("flash.ai_description_unavailable"))
    end
  end

  def approve_ai_image
    image = @product.ai_generated_images.first

    if image.present?
      @product.images.attach(image.blob)
      @product.ai_generated_images.detach
      @product.update!(ai_image_status: "approved", ai_error: nil)
      redirect_to(admin_product_path(@product), notice: t("flash.ai_image_approved"))
    else
      redirect_to(admin_product_path(@product), alert: t("flash.ai_image_unavailable"))
    end
  end

  private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(:name, :description, :price, :category_id, images: [])
    end

    def enqueue_ai_suggestions(product, force: false)
      updates = { ai_error: nil }
      updates[:ai_description_status] = "pending" if force || product.description.blank?
      updates[:ai_image_status] = "pending" if force || !product.images.attached?
      product.update!(updates) if updates.any?

      ProductAiSuggestionJob.perform_async(product.id, force)
    end

    def search_products(products)
      term = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"

      products
        .left_outer_joins(:category)
        .where(
          "products.name ILIKE :term OR products.description ILIKE :term OR categories.name ILIKE :term OR CAST(products.id AS text) ILIKE :term",
          term: term
        )
    end
end
