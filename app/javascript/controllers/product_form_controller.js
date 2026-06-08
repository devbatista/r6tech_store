import { Controller } from "@hotwired/stimulus"

// Drives the admin product form. Two responsibilities:
// 1. Switch between the simple color/storage UI and the variation builder based
//    on the selected category (categories that use RAM/storage variations).
// 2. The variation builder itself: pick color + RAM + storage + price, add rows
//    client-side, and submit them all on save. Inputs in the inactive section are
//    disabled so they never reach the server.
export default class extends Controller {
  static targets = [
    "categorySelect", "input", "note", "requiredMark",
    "simpleSection", "variantSection", "storage",
    "variantColor", "variantMemory", "variantStorage", "variantPrice",
    "variantList", "variantRow", "variantEmpty", "variantError"
  ]

  connect() {
    this.syncCategory()
  }

  categoryChanged() {
    this.syncCategory()
  }

  get usesVariants() {
    if (!this.hasCategorySelectTarget) return false
    const option = this.categorySelectTarget.selectedOptions[0]
    return option?.dataset.usesVariants === "true"
  }

  syncCategory() {
    const variants = this.usesVariants
    this.setSectionActive(this.simpleSectionTarget, !variants)
    this.setSectionActive(this.variantSectionTarget, variants)
    this.updatePrice()
  }

  // Hide a section and disable its fields so they are not submitted.
  setSectionActive(section, active) {
    if (!section) return
    section.hidden = !active
    section.querySelectorAll("input, select, textarea").forEach((field) => {
      field.disabled = !active
    })
  }

  updatePrice() {
    if (this.usesVariants) {
      this.setPriceDerived(true)
      return
    }
    // Simple categories: price is derived only when a storage option is enabled.
    const hasStorage = this.storageTargets.some((checkbox) => checkbox.checked)
    this.setPriceDerived(hasStorage)
  }

  setPriceDerived(derived) {
    if (this.hasInputTarget) {
      this.inputTarget.hidden = derived
      this.inputTarget.disabled = derived
      this.inputTarget.required = !derived
    }
    if (this.hasNoteTarget) this.noteTarget.hidden = !derived
    if (this.hasRequiredMarkTarget) this.requiredMarkTarget.hidden = derived
  }

  refreshPrice() {
    this.updatePrice()
  }

  addVariation() {
    const memory = this.variantMemoryTarget.selectedOptions[0]
    const storage = this.variantStorageTarget.selectedOptions[0]
    const color = this.variantColorTarget.selectedOptions[0]
    const price = this.variantPriceTarget.value.trim()

    if (!memory?.value || !storage?.value || price === "") {
      return this.showError(this.variantErrorTarget.dataset.incomplete)
    }

    const colorId = color?.value || ""
    if (this.isDuplicate(colorId, memory.value, storage.value)) {
      return this.showError(this.variantErrorTarget.dataset.duplicate)
    }

    this.clearError()
    this.variantListTarget.appendChild(this.buildRow({
      colorId,
      colorName: colorId ? color.text : this.variantErrorTarget.dataset.noColor,
      hex: color?.dataset.hex || "",
      memoryId: memory.value,
      memoryLabel: memory.text,
      storageId: storage.value,
      storageLabel: storage.text,
      price
    }))

    this.variantPriceTarget.value = ""
    if (this.hasVariantEmptyTarget) this.variantEmptyTarget.hidden = true
  }

  removeVariation(event) {
    event.target.closest(".variation-row")?.remove()
    if (this.hasVariantEmptyTarget && this.variantRowTargets.length === 0) {
      this.variantEmptyTarget.hidden = false
    }
  }

  isDuplicate(colorId, memoryId, storageId) {
    return this.variantRowTargets.some((row) =>
      row.dataset.colorId === colorId &&
      row.dataset.memoryId === memoryId &&
      row.dataset.storageId === storageId
    )
  }

  buildRow({ colorId, colorName, hex, memoryId, memoryLabel, storageId, storageLabel, price }) {
    const row = document.createElement("div")
    row.className = "variation-row"
    row.dataset.productFormTarget = "variantRow"
    row.dataset.colorId = colorId
    row.dataset.memoryId = memoryId
    row.dataset.storageId = storageId

    const info = document.createElement("span")
    info.className = "variation-row__info"

    if (hex) {
      const swatch = document.createElement("span")
      swatch.className = "variation-row__swatch"
      swatch.style.setProperty("--swatch", hex)
      info.appendChild(swatch)
    }

    const label = document.createElement("span")
    label.className = "variation-row__label"
    label.textContent = `${colorName} · ${memoryLabel} RAM · ${storageLabel}`
    info.appendChild(label)

    const priceLabel = document.createElement("span")
    priceLabel.className = "variation-row__price"
    priceLabel.textContent = this.formatPrice(price)
    info.appendChild(priceLabel)

    row.appendChild(info)
    row.appendChild(this.hiddenField("color_id", colorId))
    row.appendChild(this.hiddenField("memory_id", memoryId))
    row.appendChild(this.hiddenField("storage_id", storageId))
    row.appendChild(this.hiddenField("price", price))

    const remove = document.createElement("button")
    remove.type = "button"
    remove.className = "variation-row__remove"
    remove.dataset.action = "product-form#removeVariation"
    remove.innerHTML = '<i class="icon-trash-2"></i>'
    row.appendChild(remove)

    return row
  }

  hiddenField(attr, value) {
    const input = document.createElement("input")
    input.type = "hidden"
    input.name = `product_variants[][${attr}]`
    input.value = value
    return input
  }

  showError(message) {
    if (!this.hasVariantErrorTarget) return
    this.variantErrorTarget.textContent = message
    this.variantErrorTarget.hidden = false
  }

  clearError() {
    if (!this.hasVariantErrorTarget) return
    this.variantErrorTarget.hidden = true
  }

  formatPrice(value) {
    return new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(parseFloat(value))
  }
}
