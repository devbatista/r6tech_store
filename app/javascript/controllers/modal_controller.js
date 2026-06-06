import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay", "dialog", "firstInput"]
  static values = { open: Boolean }

  connect() {
    if (this.openValue || window.location.hash === "#login-modal") this.show()
  }

  open(event) {
    event.preventDefault()
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
    this.overlayTarget.classList.add("is-open")
    this.overlayTarget.setAttribute("aria-hidden", "false")
    document.body.classList.add("modal-open")
    requestAnimationFrame(() => this.firstInputTarget.focus())
  }

  hide() {
    this.overlayTarget.classList.remove("is-open")
    this.overlayTarget.setAttribute("aria-hidden", "true")
    document.body.classList.remove("modal-open")

    if (window.location.hash === "#login-modal") {
      history.replaceState(null, "", `${window.location.pathname}${window.location.search}`)
    }
  }
}
