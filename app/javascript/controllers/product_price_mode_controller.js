import { Controller } from "@hotwired/stimulus"

// On the admin product form, the base price is only edited for products without
// storage or RAM/storage variations. As soon as one is enabled, the price comes
// from the cheapest variation, so we hide/disable the base price input.
export default class extends Controller {
  static targets = ["input", "note", "requiredMark", "storage", "variant"]

  connect() {
    this.refresh()
  }

  refresh() {
    const hasVariations = [...this.storageTargets, ...this.variantTargets].some((checkbox) => checkbox.checked)

    if (this.hasInputTarget) {
      this.inputTarget.hidden = hasVariations
      this.inputTarget.disabled = hasVariations
      this.inputTarget.required = !hasVariations
    }
    if (this.hasNoteTarget) this.noteTarget.hidden = !hasVariations
    if (this.hasRequiredMarkTarget) this.requiredMarkTarget.hidden = hasVariations
  }
}
