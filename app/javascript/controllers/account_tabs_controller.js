import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel", "ordersFrame", "addressesFrame"]

  connect() {
    this.show(window.location.hash.replace("#", "") || "dashboard", false)
  }

  select(event) {
    event.preventDefault()
    this.show(event.currentTarget.dataset.accountTab)
  }

  show(name, updateUrl = true) {
    const selectedPanel = this.panelTargets.find((panel) => panel.dataset.accountPanel === name)
    if (!selectedPanel) return

    if (name !== "orders") this.resetOrders()
    if (name !== "addresses") this.resetAddresses()

    this.panelTargets.forEach((panel) => {
      const selected = panel === selectedPanel
      panel.hidden = !selected
      panel.classList.toggle("is-active", selected)
    })

    this.tabTargets.forEach((tab) => {
      const selected = tab.dataset.accountTab === name
      tab.classList.toggle("is-active", selected)
      tab.setAttribute("aria-selected", selected)
    })

    if (updateUrl) history.replaceState(null, "", `${window.location.pathname}#${name}`)
  }

  resetOrders() {
    if (!this.hasOrdersFrameTarget) return
    if (!this.ordersFrameTarget.querySelector(".account-order-detail")) return

    this.ordersFrameTarget.src = `${window.location.pathname}#orders`
  }

  resetAddresses() {
    if (!this.hasAddressesFrameTarget) return
    if (!this.addressesFrameTarget.querySelector(".account-address-form")) return

    this.addressesFrameTarget.src = `${window.location.pathname}#addresses`
  }
}
