class CartsController < BaseController
  def show
    @cart = current_cart
    @setting = Setting.instance
  end
end
