module ApplicationHelper
  def translated_order_status(status)
    t("statuses.orders.#{status}", default: status.to_s.humanize)
  end

  def translated_ai_status(status)
    t("statuses.ai.#{status}", default: status.to_s.humanize)
  end
end
