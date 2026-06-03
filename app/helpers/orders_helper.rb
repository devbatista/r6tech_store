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

  STATUS_ACTION_LABELS = {
    "paid"      => "Mark as paid",
    "shipped"   => "Mark as shipped",
    "delivered" => "Mark as delivered",
    "cancelled" => "Cancel order"
  }.freeze

  def order_status_action_label(status)
    STATUS_ACTION_LABELS.fetch(status.to_s, "Set to #{status.to_s.capitalize}")
  end
end
