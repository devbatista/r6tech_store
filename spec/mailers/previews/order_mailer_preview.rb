# Preview em http://localhost:3000/rails/mailers/order_mailer
# Usa o pedido mais recente do banco (rode `rails db:seed` se estiver vazio).
class OrderMailerPreview < ActionMailer::Preview
  def confirmation
    OrderMailer.with(order: order).confirmation
  end

  def paid
    OrderMailer.with(order: order).paid
  end

  def shipped
    OrderMailer.with(order: order).shipped
  end

  def delivered
    OrderMailer.with(order: order).delivered
  end

  private

    def order
      Order.includes(:user, order_items: :product).order(created_at: :desc).first!
    end
end
