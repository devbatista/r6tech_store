class CartMerger
  def initialize(user:, guest_cart:)
    @user = user
    @guest_cart = guest_cart
  end

  def call
    return user.carts.find_or_create_by!(status: :active) unless guest_cart&.active?

    user_cart = user.carts.find_or_create_by!(status: :active)

    Cart.transaction do
      guest_cart.cart_items.includes(:product, :color, :storage, :memory).each do |item|
        user_cart.add_product(
          item.product,
          item.quantity,
          color: item.color,
          storage: item.storage,
          memory: item.memory
        )
      end
      guest_cart.update!(status: :abandoned)
    end

    user_cart
  end

  private

    attr_reader :user, :guest_cart
end
