import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "scrollButton"]

  connect() {
    this._pinned = true
    this._autoScrollAt = 0
    this._userInitiated = false

    this._markUser = () => { this._userInitiated = true }
    this.element.addEventListener("wheel", this._markUser, { passive: true })
    this.element.addEventListener("touchmove", this._markUser, { passive: true })
    this.element.addEventListener("scroll", this._onScroll, { passive: true })

    this.scrollToBottom()

    this.observer = new MutationObserver(() => {
      if (this._pinned) this.scrollToBottom()
    })
    this.observer.observe(this.listTarget, { childList: true, subtree: true })
  }

  disconnect() {
    this.element.removeEventListener("wheel", this._markUser)
    this.element.removeEventListener("touchmove", this._markUser)
    this.element.removeEventListener("scroll", this._onScroll)
    this.observer.disconnect()
  }

  scrollToBottom() {
    this._autoScrollAt = performance.now()
    this.element.scrollTop = this.element.scrollHeight
  }

  _onScroll = () => {
    const userInitiated = this._userInitiated
    this._userInitiated = false

    // Ignore scroll events from our own scrollToBottom calls
    if (!userInitiated && performance.now() - this._autoScrollAt < 50) return

    this._pinned = this.isNearBottom()
    this._toggleButton()
  }

  jumpToBottom() {
    this._pinned = true
    this._toggleButton()
    this._autoScrollAt = performance.now()
    this.element.scrollTo({ top: this.element.scrollHeight, behavior: "smooth" })
  }

  _toggleButton() {
    if (!this.hasScrollButtonTarget) return
    this.scrollButtonTarget.toggleAttribute("data-visible", !this._pinned)
  }

  isNearBottom() {
    return this.element.scrollHeight - this.element.scrollTop - this.element.clientHeight <= 32
  }
}
