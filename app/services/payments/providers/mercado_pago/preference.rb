module Payments
  module Providers
    module MercadoPago
      # Monta o payload da preference do Checkout Pro a partir de um Payment.
      class Preference
        include Rails.application.routes.url_helpers

        # Tipos de pagamento do Mercado Pago liberados para cada método escolhido na loja.
        # Tudo que não estiver na lista é excluído do checkout hospedado.
        PAYMENT_TYPES = %w[credit_card debit_card prepaid_card ticket bank_transfer atm].freeze
        ALLOWED_TYPES_BY_METHOD = {
          "pix" => %w[bank_transfer],
          "credit_card" => %w[credit_card debit_card prepaid_card],
          "boleto" => %w[ticket]
        }.freeze
        MAX_INSTALLMENTS = 12
        STATEMENT_DESCRIPTOR_LIMIT = 22

        def initialize(payment:, setting: Setting.instance)
          @payment = payment
          @order = payment.order
          @setting = setting
        end

        def to_h
          payload = {
            items: items,
            payer: payer,
            shipments: { mode: "not_specified", cost: order.shipping_cost.to_f },
            payment_methods: {
              excluded_payment_types: excluded_payment_types,
              installments: MAX_INSTALLMENTS
            },
            external_reference: order.id,
            statement_descriptor: statement_descriptor,
            back_urls: back_urls,
            auto_return: "approved",
            metadata: { order_id: order.id, payment_id: payment.id }
          }
          payload[:notification_url] = notification_url if notification_url
          payload
        end

        private

          attr_reader :payment, :order, :setting

          def items
            order.order_items.includes(:product, :color, :memory, :storage).map do |item|
              {
                id: item.product_id,
                title: item.product.name,
                description: variant_description(item),
                category_id: "electronics",
                quantity: item.quantity,
                unit_price: item.price.to_f,
                currency_id: "BRL"
              }.compact
            end
          end

          def variant_description(item)
            [item.color&.name, ("#{item.memory.value} RAM" if item.memory), item.storage&.value].compact.join(" · ").presence
          end

          def payer
            first_name, *rest = order.user.name.to_s.split
            { name: first_name, surname: rest.join(" ").presence, email: order.user.email }.compact
          end

          def excluded_payment_types
            allowed = ALLOWED_TYPES_BY_METHOD.fetch(payment.payment_method, [])
            (PAYMENT_TYPES - allowed).map { |type| { id: type } }
          end

          def statement_descriptor
            setting.display_name.upcase.gsub(/[^A-Z0-9 ]/, "").strip.first(STATEMENT_DESCRIPTOR_LIMIT).presence
          end

          def back_urls
            url = payment_return_order_url(order, **store_url_options)
            { success: url, pending: url, failure: url }
          end

          # O Mercado Pago só consegue chamar o webhook em uma URL pública HTTPS;
          # em desenvolvimento o campo fica de fora e o status chega pela URL de retorno.
          def notification_url
            url = webhooks_mercado_pago_url(**store_url_options)
            url if url.start_with?("https://")
          end

          def store_url_options
            Rails.application.config.action_mailer.default_url_options || {}
          end
      end
    end
  end
end
