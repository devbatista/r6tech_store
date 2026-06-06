import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay"]

  connect() {
    this.show = this.show.bind(this)
    document.addEventListener("cart:open", this.show)
  }

  disconnect() {
    document.removeEventListener("cart:open", this.show)
  }

  open(event) {
    if (event) event.preventDefault()
    this.show()
  }

  close(event) {
    if (event) event.preventDefault()
    this.hide()
  }

  closeFromOverlay(event) {
    if (event.target === this.overlayTarget) this.hide()
  }

  show() {
    if (!this.hasOverlayTarget) return
    this.overlayTarget.classList.add("is-open")
    this.overlayTarget.setAttribute("aria-hidden", "false")
    document.body.classList.add("modal-open")
  }

  hide() {
    if (!this.hasOverlayTarget) return
    this.overlayTarget.classList.remove("is-open")
    this.overlayTarget.setAttribute("aria-hidden", "true")
    document.body.classList.remove("modal-open")
  }
}
