module CurrentCart
  extend ActiveSupport::Concern

  included do
    helper_method :current_cart, :cart_item_count
  end

  private

    def current_cart
      @current_cart ||= find_current_cart || create_current_cart
    end

    def find_current_cart
      if current_user
        current_user.carts.find_by(status: :active)
      elsif session[:cart_id]
        Cart.find_by(id: session[:cart_id], user_id: nil, status: :active)
      end
    end

    def create_current_cart
      cart = Cart.create!(user: current_user, status: :active)
      session[:cart_id] = cart.id unless current_user
      cart
    end

    def cart_item_count
      cart = @current_cart || find_current_cart
      cart ? cart.cart_items.sum(:quantity) : 0
    end
end
