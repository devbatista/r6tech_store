module ProductsHelper
  # Product thumbnail with a fallback when no image is attached.
  def product_thumbnail_tag(product, size: [80, 80], **options)
    if product.images.attached?
      image_tag product.images.first.variant(resize_to_fill: size), **options
    else
      content_tag :span, nil, class: "icon-image", style: "font-size: 24px;"
    end
  end
end
