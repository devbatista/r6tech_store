class CartItemsController < BaseController
  before_action :authenticate_user!
  
  def create
    product = Product.find(params[:product_id])
    quantity = params[:quantity].to_i

    result = @cart.add_product(product, quantity)

    if result
      redirect_to cart_path(@cart), notice: t("flash.product_added_to_cart")
    else
      redirect_to products_path, alert: t("flash.cart_add_failed")
    end
  end

  def update
    cart_item = @cart.cart_items.find(params[:id])
    if cart_item.update(quantity: params[:quantity])
      redirect_to cart_path(@cart), notice: t("flash.cart_quantity_updated")
    else
      redirect_to cart_path(@cart), notice: t("flash.cart_quantity_update_failed")
    end
  end

  def destroy
    cart_item = @cart.cart_items.find(params[:id])
    cart_item.destroy
    redirect_to cart_path(@cart), notice: t("flash.cart_item_removed")
  end

  private

    def set_cart
      @cart = current_user.carts.find_by(status: :active)
    end
end
