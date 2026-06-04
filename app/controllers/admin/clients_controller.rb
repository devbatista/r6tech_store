class Admin::ClientsController < Admin::BaseAdminController
  def index
    per_page = params[:per].presence || 10
    @query = params[:query].to_s.strip
    clients = User.clients.order(created_at: :desc)
    clients = search_clients(clients) if @query.present?
    @clients = clients.page(params[:page]).per(per_page)
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

  private

    def search_clients(clients)
      term = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"

      clients.where(
        "users.name ILIKE :term OR users.email ILIKE :term OR users.phone ILIKE :term OR CAST(users.id AS text) ILIKE :term",
        term: term
      )
    end
end
