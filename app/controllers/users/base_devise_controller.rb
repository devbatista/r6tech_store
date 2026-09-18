# Comportamento comum aos controllers do Devise: renderizam no layout da loja,
# que depende de current_cart/cart_item_count para o header e o drawer do carrinho.
module Users
  module BaseDeviseController
    extend ActiveSupport::Concern

    included do
      include CurrentCart
      layout "storefront"
    end

    private

      # Carrinho criado enquanto o visitante navegava sem login.
      def guest_cart
        Cart.find_by(id: session[:cart_id], user_id: nil, status: :active)
      end

      def merge_guest_cart_into(user, cart)
        CartMerger.new(user: user, guest_cart: cart).call if user.customer?
        session.delete(:cart_id)
      end

      def after_sign_in_path_for(resource)
        return admin_root_path if resource.admin?

        stored_location_for(resource) || root_path
      end
  end
end
