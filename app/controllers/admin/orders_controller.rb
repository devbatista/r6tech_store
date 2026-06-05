class Admin::OrdersController < Admin::BaseAdminController
  def index
    per_page = params[:per].presence || 10
    @orders = Order.includes(:user, order_items: { product: { images_attachments: :blob } })
                   .order(created_at: :desc)
                   .page(params[:page]).per(per_page)
  end

  def show
    @order = Order.includes(order_items: { product: { images_attachments: :blob } })
                  .find(params[:id])
  end

  def update_status
    @order = Order.find(params[:id])
    new_status = params[:status]

    if @order.can_transition_to?(new_status)
      @order.update!(status: new_status)
      redirect_to admin_order_path(@order), notice: t("flash.order_status_updated", status: helpers.translated_order_status(new_status))
    else
      redirect_to admin_order_path(@order), alert: t("flash.invalid_status_transition")
    end
  end
end
