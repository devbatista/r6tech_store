class ProductsController < BaseController
  before_action :set_product, only: :show

  def index
    @query = params[:query].to_s.strip
    @category = Category.find_by(id: params[:category_id])
    @categories = Category.roots.includes(:subcategories)

    products = Product.with_attached_images.includes(:category)
    products = search(products) if @query.present?
    products = products.where(category_id: [@category.id, *@category.descendant_ids]) if @category
    @products = sort(products).page(params[:page]).per(12)
  end

  def show
    @related_products = Product
      .with_attached_images
      .where(category_id: @product.category_id)
      .where.not(id: @product.id)
      .limit(4)
  end

  private

    def set_product
      @product = Product.find(params[:id])
    end

    def search(products)
      term = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"
      products.left_joins(:category).where(
        "products.name ILIKE :term OR products.description ILIKE :term OR categories.name ILIKE :term",
        term: term
      )
    end

    def sort(products)
      case params[:sort]
      when "name_asc" then products.order(name: :asc)
      when "price_asc" then products.order(price: :asc)
      when "price_desc" then products.order(price: :desc)
      else products.order(created_at: :desc)
      end
    end
end
