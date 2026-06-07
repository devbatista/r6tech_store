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
      params.require(:product).permit(:name, :description, :price, :category_id, images: [], color_ids: [])
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

      variant_prices = params.fetch(:product_variants, {}).values.flat_map(&:values).filter_map do |attrs|
        attrs[:price].to_d if attrs[:enabled] == "1" && attrs[:price].present?
      end

      (storage_prices + variant_prices).min
    end

    # Storages carry a per-product price, so they can't ride along in product_params.
    # Each submitted row is "enabled" + "price"; we upsert enabled ones and drop the rest.
    def sync_product_storages(product)
      return product.product_storages.destroy_all if submitted_product_variants?

      submitted = params.fetch(:product_storages, {})

      submitted.each do |storage_id, attrs|
        if attrs[:enabled] == "1" && attrs[:price].present?
          product.product_storages.find_or_initialize_by(storage_id: storage_id).update(price: attrs[:price])
        else
          product.product_storages.find_by(storage_id: storage_id)&.destroy
        end
      end
    end

    def sync_product_variants(product)
      submitted = params.fetch(:product_variants, {})
      enabled_keys = []

      submitted.each do |memory_id, storages|
        storages.each do |storage_id, attrs|
          next unless attrs[:enabled] == "1" && attrs[:price].present?

          enabled_keys << [memory_id, storage_id]
          product.product_variants
            .find_or_initialize_by(memory_id: memory_id, storage_id: storage_id)
            .update!(price: attrs[:price])
        end
      end

      product.product_variants.each do |variant|
        variant.destroy unless enabled_keys.include?([variant.memory_id, variant.storage_id])
      end
    end

    def submitted_product_variants?
      params.fetch(:product_variants, {}).values.any? do |storages|
        storages.values.any? { |attrs| attrs[:enabled] == "1" && attrs[:price].present? }
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
