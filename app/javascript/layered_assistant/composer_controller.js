import { Controller } from "@hotwired/stimulus"

// Manages the message composer form. Toggles the submit button between
// "Send" and "Stop" depending on whether the assistant is responding,
// and disables "Send" when the input is empty.
export default class extends Controller {
  static targets = ["form", "input", "sendButton", "stopButton"]
  static values = {
    responding: { type: Boolean, default: false },
    stopUrl: { type: String, default: "" }
  }

  connect() {
    this._onChunkReceived = () => this._resetRespondingTimeout()
    document.addEventListener("assistant:chunk-received", this._onChunkReceived)
    this._applyRespondingState()
    this.updateButtonDisabled()
  }

  disconnect() {
    document.removeEventListener("assistant:chunk-received", this._onChunkReceived)
    clearTimeout(this._respondingTimeout)
  }

  respondingValueChanged() {
    this._applyRespondingState()
  }

  // Enter submits, Shift+Enter is a no-op (default newline),
  // Alt+Enter inserts a newline without submitting.
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

    // Dismiss the on-screen keyboard on touch devices
    if ("ontouchstart" in window) {
      this.inputTarget.blur()
    }
  }

  // Ask the server to stop the current response, then reset the composer.
  // On failure the composer resets anyway so the user is not stuck.
  stop(event) {
    event.preventDefault()

    if (!this.stopUrlValue) return

    const token = document.querySelector('meta[name="csrf-token"]')?.content
    fetch(this.stopUrlValue, {
      method: "PATCH",
      headers: {
        "X-CSRF-Token": token,
        "Accept": "text/vnd.turbo-stream.html"
      }
    }).then(response => {
      if (response.ok) this.respondingValue = false
    }).catch(() => {
      this.respondingValue = false
    })
  }

  // Disable the send button when the input is empty. Called from the
  // `input` event on the textarea and after responding state changes.
  updateButtonDisabled() {
    if (this.respondingValue) return

    const empty = this.inputTarget.value.trim() === ""
    this.sendButtonTarget.disabled = empty
    this.sendButtonTarget.classList.toggle("l-ui-button--disabled", empty)
  }

  // Toggle visibility of the Send and Stop buttons. While responding a
  // 60-second safety timeout resets the composer in case the server
  // never signals completion. The timeout is reset each time a chunk
  // is received so long-running responses are not interrupted.
  _applyRespondingState() {
    clearTimeout(this._respondingTimeout)

    if (this.respondingValue) {
      this.sendButtonTarget.hidden = true
      this.stopButtonTarget.hidden = false

      this._resetRespondingTimeout()
    } else {
      this.stopButtonTarget.hidden = true
      this.sendButtonTarget.hidden = false
      this.updateButtonDisabled()

      if (!this.element.closest("turbo-frame")) {
        this.inputTarget.focus()
      }
    }
  }

  _resetRespondingTimeout() {
    if (!this.respondingValue) return
    clearTimeout(this._respondingTimeout)
    this._respondingTimeout = setTimeout(() => {
      this.respondingValue = false
      document.dispatchEvent(new CustomEvent("assistant:response-timeout"))
    }, 30000)
  }
}
