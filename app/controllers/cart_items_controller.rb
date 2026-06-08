class CartItemsController < BaseController
  before_action :set_cart_item, only: [:update, :destroy]
  
  def create
    product = Product.find(params[:product_id])
    quantity = [params.fetch(:quantity, 1).to_i, 1].max
    variant = product.product_variants.find_by(id: params[:variant_id])
    color = variant&.color || product.colors.find_by(id: params[:color_id])
    storage = variant&.storage || product.storages.find_by(id: params[:storage_id])
    memory = variant&.memory

    if missing_required_options?(product, color, storage, memory)
      return redirect_to product_path(product), alert: t("flash.select_options"), status: :see_other
    end

    result = current_cart.add_product(product, quantity, color: color, storage: storage, memory: memory)

    respond_to do |format|
      format.turbo_stream
      format.html do
        if result
          redirect_to cart_path, notice: t("flash.product_added_to_cart"), status: :see_other
        else
          redirect_to products_path, alert: t("flash.cart_add_failed")
        end
      end
    end
  end

  def update
    updated = @cart_item.update(quantity: params[:quantity])

    respond_to do |format|
      format.turbo_stream
      format.html do
        if updated
          redirect_to cart_path, notice: t("flash.cart_quantity_updated"), status: :see_other
        else
          redirect_to cart_path, alert: t("flash.cart_quantity_update_failed"), status: :see_other
        end
      end
    end
  end

  def destroy
    @cart_item.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to cart_path, notice: t("flash.cart_item_removed"), status: :see_other }
    end
  end

  private

    def set_cart_item
      @cart_item = current_cart.cart_items.find(params[:id])
    end

    def missing_required_options?(product, color, storage, memory)
      (product.product_colors.any? && color.nil?) ||
        (product.product_storages.any? && storage.nil?) ||
        (product.product_variants.any? && (storage.nil? || memory.nil?))
    end
end
