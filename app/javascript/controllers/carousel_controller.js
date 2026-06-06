import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slide"]

  connect() {
    this.index = 0
    this.timer = setInterval(() => this.advance(), 6000)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  show(event) {
    this.activate(Number(event.currentTarget.dataset.index))
  }

  advance() {
    this.activate((this.index + 1) % this.slideTargets.length)
  }

  activate(index) {
    this.slideTargets.forEach((slide, position) => slide.classList.toggle("is-active", position === index))
    this.index = index
  }
}
