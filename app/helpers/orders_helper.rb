module OrdersHelper
  ORDER_STATUS_BADGES = {
    "pending"   => "block-pending",
    "paid"      => "block-available",
    "shipped"   => "block-published",
    "delivered" => "block-available",
    "cancelled" => "block-not-available"
  }.freeze

  def order_status_badge_class(status)
    ORDER_STATUS_BADGES.fetch(status.to_s, "block-warning")
  end
end
