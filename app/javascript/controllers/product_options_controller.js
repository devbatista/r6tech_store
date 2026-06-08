import { Controller } from "@hotwired/stimulus"

// Storefront product options. For simple products the price follows the chosen
// storage and the color is cosmetic. For variant products each color + RAM +
// storage combination is its own SKU: picking a color filters the available
// configurations, and the pair resolves to a variant id + price.
export default class extends Controller {
  static targets = ["price", "colorName", "variantId", "color", "config"]
  static values = { variants: Array }

  connect() {
    if (this.hasVariantsValue && this.variantsValue.length > 0) {
      this.refreshConfigs()
    }
  }

  selectColor(event) {
    if (this.hasColorNameTarget) {
      this.colorNameTarget.textContent = event.target.dataset.colorName
    }
    if (this.hasConfigTarget) this.refreshConfigs()
  }

  selectConfig() {
    this.updateVariant()
  }

  // Simple (storage-only) products: price comes straight from the chosen option.
  selectStorage(event) {
    const price = parseFloat(event.target.dataset.price)
    if (this.hasPriceTarget && !Number.isNaN(price)) {
      this.priceTarget.textContent = this.format(price)
    }
  }

  refreshConfigs() {
    const colorId = this.currentColorId()
    let firstEnabled = null

    this.configTargets.forEach((radio) => {
      const exists = this.variantsValue.some((v) =>
        v.colorId === colorId &&
        v.memoryId === radio.dataset.memoryId &&
        v.storageId === radio.dataset.storageId
      )
      radio.disabled = !exists
      const pill = radio.closest(".storage-pill")
      if (pill) pill.classList.toggle("storage-pill--disabled", !exists)
      if (exists && firstEnabled === null) firstEnabled = radio
    })

    const checked = this.configTargets.find((radio) => radio.checked && !radio.disabled)
    if (!checked && firstEnabled) firstEnabled.checked = true

    this.updateVariant()
  }

  updateVariant() {
    const colorId = this.currentColorId()
    const config = this.configTargets.find((radio) => radio.checked && !radio.disabled)
    if (!config) return

    const variant = this.variantsValue.find((v) =>
      v.colorId === colorId &&
      v.memoryId === config.dataset.memoryId &&
      v.storageId === config.dataset.storageId
    )
    if (!variant) return

    if (this.hasVariantIdTarget) this.variantIdTarget.value = variant.id
    if (this.hasPriceTarget) this.priceTarget.textContent = this.format(variant.price)
  }

  currentColorId() {
    const checked = this.colorTargets.find((radio) => radio.checked)
    return checked ? checked.value : ""
  }

  format(value) {
    return new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(value)
  }
}
