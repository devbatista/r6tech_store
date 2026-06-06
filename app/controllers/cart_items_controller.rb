class CartItemsController < BaseController
  before_action :set_cart_item, only: [:update, :destroy]
  
  def create
    product = Product.find(params[:product_id])
    quantity = [params.fetch(:quantity, 1).to_i, 1].max

    result = current_cart.add_product(product, quantity)

    if result
      redirect_to cart_path, notice: t("flash.product_added_to_cart"), status: :see_other
    else
      redirect_to products_path, alert: t("flash.cart_add_failed")
    end
  end

  def update
    if @cart_item.update(quantity: params[:quantity])
      redirect_to cart_path, notice: t("flash.cart_quantity_updated"), status: :see_other
    else
      redirect_to cart_path, alert: t("flash.cart_quantity_update_failed"), status: :see_other
    end
  end

  def destroy
    @cart_item.destroy
    redirect_to cart_path, notice: t("flash.cart_item_removed"), status: :see_other
  end

  private

    def set_cart_item
      @cart_item = current_cart.cart_items.find(params[:id])
    end
end
