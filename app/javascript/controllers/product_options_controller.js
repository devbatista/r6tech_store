import { Controller } from "@hotwired/stimulus"

// Updates the displayed price and selected color name as the customer picks
// product options. Price depends on the chosen storage; color is cosmetic.
export default class extends Controller {
  static targets = ["price", "colorName"]

  selectStorage(event) {
    const price = parseFloat(event.target.dataset.price)
    if (this.hasPriceTarget && !Number.isNaN(price)) {
      this.priceTarget.textContent = this.format(price)
    }
  }

  selectColor(event) {
    if (this.hasColorNameTarget) {
      this.colorNameTarget.textContent = event.target.dataset.colorName
    }
  }

  format(value) {
    return new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(value)
  }
}
