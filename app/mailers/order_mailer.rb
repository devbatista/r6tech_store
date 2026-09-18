# E-mails transacionais do pedido. Cada ação corresponde a um status do pedido;
# a confirmação é enviada na criação (status `pending`).
class OrderMailer < ApplicationMailer
  helper :application

  before_action :load_order

  def confirmation
    notify(:confirmation)
  end

  def paid
    notify(:paid)
  end

  def shipped
    notify(:shipped)
  end

  def delivered
    notify(:delivered)
  end

  private

    attr_reader :order

    def load_order
      @order = params[:order]
      @setting = Setting.instance
      @store_name = @setting.display_name
      @order_number = order.id.to_s.first(8).upcase
    end

    def notify(template)
      mail(
        to: email_address_with_name(order.user.email, order.user.name),
        subject: t("order_mailer.#{template}.subject", number: @order_number, store: @store_name),
        template_name: template.to_s
      )
    end
end
