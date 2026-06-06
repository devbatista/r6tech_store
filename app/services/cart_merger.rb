class CartMerger
  def initialize(user:, guest_cart:)
    @user = user
    @guest_cart = guest_cart
  end

  def call
    return user.carts.find_or_create_by!(status: :active) unless guest_cart&.active?

    user_cart = user.carts.find_or_create_by!(status: :active)

    Cart.transaction do
      guest_cart.cart_items.includes(:product).each do |item|
        user_cart.add_product(item.product, item.quantity)
      end
      guest_cart.update!(status: :abandoned)
    end

    user_cart
  end

  private

    attr_reader :user, :guest_cart
end
