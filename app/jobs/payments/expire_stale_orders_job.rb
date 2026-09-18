module Payments
  # Cancela pedidos pendentes cujo pagamento nunca foi concluído. Boletos vencem em
  # 3 dias no Mercado Pago, então depois desse prazo o pedido não tem mais como ser pago.
  class ExpireStaleOrdersJob < ApplicationJob
    STALE_AFTER = 3.days

    queue_as :default

    def perform
      stale_orders.find_each do |order|
        order.update!(status: :cancelled)
      end
    end

    private

      def stale_orders
        Order.pending
             .joins(:payment)
             .where(payments: { status: %w[awaiting_payment failed] })
             .where(orders: { created_at: ...STALE_AFTER.ago })
      end
  end
end
