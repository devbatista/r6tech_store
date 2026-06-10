module ApplicationHelper
  CATEGORY_IMAGES = %w[
    storefront/categories/category-1.jpg
    storefront/categories/category-2.jpg
    storefront/categories/category-3.jpg
    storefront/categories/category-4.png
    storefront/categories/category-5.jpg
    storefront/categories/category-6.jpg
  ].freeze

  def translated_order_status(status)
    t("statuses.orders.#{status}", default: status.to_s.humanize)
  end

  def order_progress_steps(order)
    return [%w[placed complete], %w[cancelled complete]] if order.cancelled?

    statuses = %w[pending paid shipped delivered]
    current_index = statuses.index(order.status) || 0
    statuses.each_with_index.map do |status, index|
      [status == "pending" ? "placed" : status, index <= current_index ? "complete" : "pending"]
    end
  end

  def translated_ai_status(status)
    t("statuses.ai.#{status}", default: status.to_s.humanize)
  end

  def storefront_setting
    @storefront_setting ||= Setting.instance
  end

  def storefront_name
    storefront_setting.store_name.presence || "R6tech Store"
  end

  def storefront_whatsapp_url(message: nil)
    phone = storefront_setting.whatsapp.presence || storefront_setting.contact_phone
    digits = phone.to_s.gsub(/\D/, "")
    return if digits.blank?

    digits = "55#{digits}" if digits.length.in?([10, 11])
    url = "https://wa.me/#{digits}"
    message.present? ? "#{url}?text=#{ERB::Util.url_encode(message)}" : url
  end

  def product_image(product, class_name: nil)
    if product.images.attached?
      image_tag product.images.first, alt: product.name, class: class_name
    else
      image_tag "storefront/product-placeholder.jpg", alt: product.name, class: class_name
    end
  end

  # Human-readable label for a chosen variant, e.g. "Titanium black · 16GB RAM · 512GB".
  def variant_label(item)
    parts = [item.color&.name, ("#{item.memory.value} RAM" if item.memory), item.storage&.value].compact
    parts.join(" · ").presence
  end

  def category_image(category, index = 0)
    image_tag CATEGORY_IMAGES[index % CATEGORY_IMAGES.length], alt: category.name
  end

  def category_product_count(category)
    Product.where(category_id: [category.id, *category.descendant_ids]).count
  end

  def active_category_params(category)
    { category_id: category.id, query: params[:query], sort: params[:sort] }.compact
  end
end
