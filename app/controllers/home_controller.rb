class HomeController < BaseController
  def index
    @setting = Setting.instance
    @categories = Category.roots.includes(:subcategories).limit(6)
    @featured_products = Product.with_attached_images.includes(:category).order(created_at: :desc).limit(8)
    @best_sellers = Product
      .with_attached_images
      .includes(:category)
      .left_joins(:order_items)
      .group(:id)
      .order(Arel.sql("COALESCE(SUM(order_items.quantity), 0) DESC"), created_at: :desc)
      .limit(8)
  end
end
