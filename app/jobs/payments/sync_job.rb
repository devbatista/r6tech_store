module Payments
  # Processa a notificação do webhook fora da requisição: o Mercado Pago espera
  # resposta rápida e reenvia se a chamada falhar, então erros aqui só geram retry.
  class SyncJob < ApplicationJob
    queue_as :default

    retry_on Payments::ProviderError, wait: :polynomially_longer, attempts: 5

    def perform(provider_payment_id)
      Payments::Sync.call(provider_payment_id: provider_payment_id)
    end
  end
end
