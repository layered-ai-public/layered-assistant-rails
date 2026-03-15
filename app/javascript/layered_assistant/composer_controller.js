import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input", "button"]
  static values = { responding: { type: Boolean, default: false } }

  connect() {
    this._applyRespondingState()
  }

  respondingValueChanged() {
    this._applyRespondingState()
  }

  submitOnEnter(event) {
    if (event.key !== "Enter") return
    if (event.shiftKey) return

    event.preventDefault()

    if (event.altKey) {
      this.inputTarget.setRangeText("\n", this.inputTarget.selectionStart, this.inputTarget.selectionEnd, "end")
    } else if (!this.respondingValue && this.inputTarget.value.trim() !== "") {
      this.formTarget.requestSubmit()
    }
  }

  submit() {
    this.respondingValue = true

    if ("ontouchstart" in window) {
      this.inputTarget.blur()
    }
  }

  _applyRespondingState() {
    this.buttonTarget.disabled = this.respondingValue
    this.buttonTarget.classList.toggle("l-ui-button--disabled", this.respondingValue)

    clearTimeout(this._respondingTimeout)

    if (this.respondingValue) {
      this._respondingTimeout = setTimeout(() => { this.respondingValue = false }, 60000)
    } else if (!this.element.closest("turbo-frame")) {
      this.inputTarget.focus()
    }
  }
}
