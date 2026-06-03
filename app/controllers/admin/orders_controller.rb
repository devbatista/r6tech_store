class Admin::OrdersController < Admin::BaseAdminController
  def index
    per_page = params[:per].presence || 10
    @orders = Order.includes(:user, order_items: { product: { images_attachments: :blob } })
                   .order(created_at: :desc)
                   .page(params[:page]).per(per_page)
  end

  def show
    @order = Order.includes(order_items: { product: { images_attachments: :blob } })
                  .find(params[:id])
  end
end
