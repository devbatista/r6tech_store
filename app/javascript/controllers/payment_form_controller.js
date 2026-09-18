import { Controller } from "@hotwired/stimulus"

// Atualiza frete e total do resumo conforme a opção de entrega escolhida.
// O pagamento em si acontece no Checkout Pro do Mercado Pago, fora da loja.
export default class extends Controller {
  static targets = ["shipping", "shippingCost", "total"]
  static values = { subtotal: Number }

  connect() {
    this.syncShipping()
  }

  syncShipping() {
    const selected = this.shippingTargets.find((shipping) => shipping.checked)
    if (!selected) return

    const price = Number(selected.dataset.price)
    this.shippingCostTarget.textContent = price === 0 ? selected.dataset.freeLabel : this.currency(price)
    this.totalTarget.textContent = this.currency(this.subtotalValue + price)
  }

  currency(value) {
    return new Intl.NumberFormat(document.documentElement.lang || "pt-BR", {
      style: "currency",
      currency: "BRL"
    }).format(value)
  }
}
