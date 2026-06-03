class Admin::ClientsController < Admin::BaseAdminController
  def index
    per_page = params[:per].presence || 10
    @clients = User.clients.page(params[:page]).per(per_page)
  end

  def show
    @client = User.clients.find(params[:id])
    @addresses = @client.addresses.order(default: :desc, created_at: :asc)
    @recent_orders = @client.orders
                            .includes(order_items: { product: { images_attachments: :blob } })
                            .order(created_at: :desc)
                            .limit(5)
    @orders_count = @client.orders.count
  end
end
