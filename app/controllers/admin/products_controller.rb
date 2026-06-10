class Admin::ProductsController < Admin::BaseAdminController
  before_action :set_product, only: [
    :show,
    :edit,
    :update,
    :destroy,
    :generate_ai_suggestions,
    :approve_ai_description,
    :approve_ai_image
  ]

  def index
    per_page = params[:per].presence || 10
    @query = params[:query].to_s.strip
    products = Product.includes(:category).order(created_at: :desc)
    products = search_products(products) if @query.present?
    @products = products.page(params[:page]).per(per_page)
  end

  def show;end

  def new
    @product = Product.new  
  end

  def create
    @product = Product.new(product_params)
    assign_base_price(@product)

    if @product.save
      sync_product_storages(@product)
      sync_product_variants(@product)
      enqueue_ai_suggestions(@product) if @product.needs_ai_suggestions?
      redirect_to(admin_product_path(@product), notice: t("flash.product_created"))
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit;end

  def update
    @product.assign_attributes(product_params)
    assign_base_price(@product)

    if @product.save
      sync_product_storages(@product)
      sync_product_variants(@product)
      redirect_to(admin_product_path(@product), notice: t("flash.product_updated"))
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @product.destroy
      redirect_to(admin_products_path, notice: t("flash.product_removed"), status: :see_other)
    else
      redirect_to(admin_products_path, alert: @product.errors.full_messages, status: :see_other)
    end
  end

  def generate_ai_suggestions
    enqueue_ai_suggestions(@product, force: true)
    redirect_to(admin_product_path(@product), notice: t("flash.ai_suggestions_generating"))
  end

  def approve_ai_description
    if @product.ai_description.present?
      @product.update!(description: @product.ai_description, ai_description_status: "approved", ai_error: nil)
      redirect_to(admin_product_path(@product), notice: t("flash.ai_description_approved"))
    else
      redirect_to(admin_product_path(@product), alert: t("flash.ai_description_unavailable"))
    end
  end

  def approve_ai_image
    image = @product.ai_generated_images.first

    if image.present?
      @product.images.attach(image.blob)
      @product.ai_generated_images.detach
      @product.update!(ai_image_status: "approved", ai_error: nil)
      redirect_to(admin_product_path(@product), notice: t("flash.ai_image_approved"))
    else
      redirect_to(admin_product_path(@product), alert: t("flash.ai_image_unavailable"))
    end
  end

  private

    def set_product
      @product = Product.find(params[:id])
    end

    def product_params
      params.require(:product).permit(
        :name, :description, :price, :category_id, :weight, :width, :height, :length,
        images: [], color_ids: []
      )
    end

    # When the product has storage variations, its base price is derived from the
    # cheapest variation (the catalog "a partir de" price). Without variations the
    # admin sets the base price directly.
    def assign_base_price(product)
      base = derived_base_price
      product.price = base if base
    end

    def derived_base_price
      storage_prices = params.fetch(:product_storages, {}).values.filter_map do |attrs|
        attrs[:price].to_d if attrs[:enabled] == "1" && attrs[:price].present?
      end

      variant_prices = submitted_variant_rows.map { |attrs| attrs[:price].to_d }

      (storage_prices + variant_prices).min
    end

    # Storages carry a per-product price, so they can't ride along in product_params.
    # Variant products don't use simple storages, so we clear them in that case.
    # Otherwise each submitted row is "enabled" + "price"; upsert enabled, drop rest.
    def sync_product_storages(product)
      return product.product_storages.destroy_all if product.category&.uses_variants?

      submitted = params.fetch(:product_storages, {})

      submitted.each do |storage_id, attrs|
        if attrs[:enabled] == "1" && attrs[:price].present?
          product.product_storages.find_or_initialize_by(storage_id: storage_id).update(price: attrs[:price])
        else
          product.product_storages.find_by(storage_id: storage_id)&.destroy
        end
      end
    end

    # The variation builder submits the full desired set of rows on every save, so
    # we rebuild from scratch. Each row is color (optional) + RAM + storage + price.
    # Variant products carry no separate color list (colors live on the variations).
    def sync_product_variants(product)
      return product.product_variants.destroy_all unless product.category&.uses_variants?

      product.product_variants.destroy_all
      product.product_colors.destroy_all

      submitted_variant_rows.each do |attrs|
        product.product_variants.create!(
          color_id: attrs[:color_id].presence,
          memory_id: attrs[:memory_id],
          storage_id: attrs[:storage_id],
          price: attrs[:price]
        )
      end
    end

    # Valid variation rows submitted by the builder (array of color/RAM/storage/price).
    def submitted_variant_rows
      Array(params[:product_variants]).select do |attrs|
        attrs[:memory_id].present? && attrs[:storage_id].present? && attrs[:price].present?
      end
    end

    def enqueue_ai_suggestions(product, force: false)
      updates = { ai_error: nil }
      updates[:ai_description_status] = "pending" if force || product.description.blank?
      updates[:ai_image_status] = "pending" if force || !product.images.attached?
      product.update!(updates) if updates.any?

      ProductAiSuggestionJob.perform_async(product.id, force)
    end

    def search_products(products)
      term = "%#{ActiveRecord::Base.sanitize_sql_like(@query)}%"

      products
        .left_outer_joins(:category)
        .where(
          "products.name ILIKE :term OR products.description ILIKE :term OR categories.name ILIKE :term OR CAST(products.id AS text) ILIKE :term",
          term: term
        )
    end
end
