class Admin::ProductsController < Admin::BaseAdminController
  before_action :set_product, only: [:show, :edit, :update, :destroy]

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
      redirect_to(admin_product_path(@product), notice: "Product created successfully")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit;end

  def update
    if @product.update(product_params)
      redirect_to(admin_product_path(@product), notice: "Product updated successfully")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @product.destroy
      redirect_to(admin_products_path, notice: "Product deleted", status: :see_other)
    else
      redirect_to(admin_products_path, alert: @product.errors.full_messages, status: :see_other)
    end
  end

  private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(:name, :description, :price, :category_id, images: [])
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
