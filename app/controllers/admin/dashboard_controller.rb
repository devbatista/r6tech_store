class Admin::DashboardController < Admin::BaseAdminController
  REVENUE_STATUSES = %w[paid shipped delivered].freeze

  def index
    @total_revenue   = Order.where(status: REVENUE_STATUSES).sum(:total)
    @total_orders    = Order.count
    @total_customers = User.clients.count
    @total_products  = Product.count

    @revenue_growth   = month_over_month_growth(Order.where(status: REVENUE_STATUSES), :total)
    @orders_growth    = month_over_month_growth(Order.all)
    @customers_growth = month_over_month_growth(User.clients)

    @average_ticket = @total_orders.zero? ? 0 : (@total_revenue / @total_orders)

    @orders_by_status = Order.group(:status).count

    @recent_orders = Order.includes(:user, order_items: { product: { images_attachments: :blob } })
                          .order(created_at: :desc)
                          .limit(5)

    @top_products = Product.joins(:order_items)
                           .select("products.*, SUM(order_items.quantity) AS sold_quantity")
                           .group("products.id")
                           .order("sold_quantity DESC")
                           .limit(6)
  end

  private

    # Percentage growth of the current month compared to the previous month.
    # When `column` is given it sums the column; otherwise it counts records.
    def month_over_month_growth(scope, column = nil)
      current_start  = Time.current.beginning_of_month
      previous_start = 1.month.ago.beginning_of_month

      current  = aggregate(scope.where(created_at: current_start..), column)
      previous = aggregate(scope.where(created_at: previous_start...current_start), column)

      return 0 if previous.zero?

      (((current - previous) / previous.to_f) * 100).round(2)
    end

    def aggregate(scope, column)
      column ? scope.sum(column) : scope.count
    end
end
