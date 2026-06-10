import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "method", "cardFields", "cardInput", "cardNumber", "expiry", "brand",
    "shipping", "shippingCost", "total"
  ]
  static values = { subtotal: Number }

  connect() {
    this.syncMethod()
    this.syncShipping()
  }

  syncMethod() {
    const creditCardSelected = this.methodTargets.some((method) =>
      method.checked && method.value === "credit_card"
    )

    this.cardFieldsTarget.hidden = !creditCardSelected
    this.cardInputTargets.forEach((input) => {
      input.disabled = !creditCardSelected
    })
  }

  formatCardNumber() {
    const digits = this.cardNumberTarget.value.replace(/\D/g, "").slice(0, 19)
    this.cardNumberTarget.value = digits.replace(/(\d{4})(?=\d)/g, "$1 ")
    this.brandTarget.textContent = this.cardBrand(digits)
  }

  formatExpiry() {
    const digits = this.expiryTarget.value.replace(/\D/g, "").slice(0, 4)
    this.expiryTarget.value = digits.length > 2 ? `${digits.slice(0, 2)}/${digits.slice(2)}` : digits
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

  cardBrand(number) {
    if (/^4/.test(number)) return "Visa"
    if (/^(5[1-5]|2[2-7])/.test(number)) return "Mastercard"
    if (/^3[47]/.test(number)) return "American Express"
    if (/^(4011|4312|4389|4514|4576|5041|5066|5067|5090|6277|6362|6363|650|6516|6550)/.test(number)) return "Elo"

    return ""
  }
}
