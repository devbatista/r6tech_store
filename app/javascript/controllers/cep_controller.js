import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "zipCode", "street", "neighborhood", "city", "state", "country", "status",
    "streetHidden", "neighborhoodHidden", "cityHidden", "stateHidden", "countryHidden"
  ]

  connect() {
    this.timeout = null
    if (this.normalizedCep.length === 8) this.lookup()
  }

  disconnect() {
    clearTimeout(this.timeout)
  }

  schedule() {
    clearTimeout(this.timeout)
    this.unlockAddressFields()
    this.statusTarget.textContent = ""

    if (this.normalizedCep.length !== 8) return
    this.timeout = setTimeout(() => this.lookup(), 250)
  }

  async lookup() {
    if (this.normalizedCep.length !== 8) return

    this.statusTarget.textContent = this.statusTarget.dataset.loading

    try {
      const response = await fetch(`https://viacep.com.br/ws/${this.normalizedCep}/json/`)
      const address = await response.json()
      if (!response.ok || address.erro) throw new Error("CEP not found")

      this.zipCodeTarget.value = address.cep
      this.fillAndLock(this.streetTarget, this.streetHiddenTarget, address.logradouro)
      this.fillAndLock(this.neighborhoodTarget, this.neighborhoodHiddenTarget, address.bairro)
      this.fillAndLock(this.cityTarget, this.cityHiddenTarget, address.localidade)
      this.fillAndLock(this.stateTarget, this.stateHiddenTarget, address.uf)
      this.fillAndLock(this.countryTarget, this.countryHiddenTarget, "Brasil")
      this.statusTarget.textContent = this.statusTarget.dataset.success
    } catch (_error) {
      this.unlockAddressFields()
      this.statusTarget.textContent = this.statusTarget.dataset.error
    }
  }

  fillAndLock(field, hiddenField, value) {
    if (!value) return

    field.value = value
    field.disabled = true
    field.classList.add("is-locked")
    hiddenField.value = value
    hiddenField.disabled = false
  }

  unlockAddressFields() {
    this.fieldPairs.forEach(([field, hiddenField]) => {
      field.disabled = false
      field.classList.remove("is-locked")
      hiddenField.disabled = true
    })
  }

  get normalizedCep() {
    return this.zipCodeTarget.value.replace(/\D/g, "")
  }

  get fieldPairs() {
    return [
      [this.streetTarget, this.streetHiddenTarget],
      [this.neighborhoodTarget, this.neighborhoodHiddenTarget],
      [this.cityTarget, this.cityHiddenTarget],
      [this.stateTarget, this.stateHiddenTarget],
      [this.countryTarget, this.countryHiddenTarget]
    ]
  }
}
