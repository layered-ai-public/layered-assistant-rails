import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "input", "button"]

  connect() {
    if (!this.element.closest("turbo-frame")) {
      this.inputTarget.focus()
    }
  }

  submitOnEnter(event) {
    if (event.key !== "Enter") return
    if (event.shiftKey) return

    event.preventDefault()

    if (event.altKey) {
      this.inputTarget.setRangeText("\n", this.inputTarget.selectionStart, this.inputTarget.selectionEnd, "end")
    } else if (this.inputTarget.value.trim() !== "") {
      this.formTarget.requestSubmit()
    }
  }

  submit() {
    if ("ontouchstart" in window) {
      this.inputTarget.blur()
    }
  }
}
