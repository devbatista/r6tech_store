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
    "paid"      => "statuses.order_actions.paid",
    "shipped"   => "statuses.order_actions.shipped",
    "delivered" => "statuses.order_actions.delivered",
    "cancelled" => "statuses.order_actions.cancelled"
  }.freeze

  def order_status_action_label(status)
    key = STATUS_ACTION_LABELS[status.to_s]
    return t(key) if key

    t("statuses.order_actions.fallback", status: translated_order_status(status))
  end
end
