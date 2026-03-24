import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "scrollButton"]

  connect() {
    this._pinned = true
    this._autoScrollAt = 0
    this._userInitiated = false

    this._markUser = () => { this._userInitiated = true }
    this._onTimeout = () => {
      this.listTarget.querySelectorAll(".l-ui-typing-indicator").forEach(el => {
        const body = el.closest(".l-ui-message__body")
        el.remove()
        if (body && body.children.length === 0) {
          body.insertAdjacentHTML("beforeend", '<div class="l-ui-notice--error" role="status">The response could not be completed.</div>')
        }
      })
    }
    this.element.addEventListener("wheel", this._markUser, { passive: true })
    this.element.addEventListener("touchmove", this._markUser, { passive: true })
    this.element.addEventListener("scroll", this._onScroll, { passive: true })
    document.addEventListener("assistant:response-timeout", this._onTimeout)

    this.scrollToBottom()

    this.observer = new MutationObserver((mutations) => {
      if (this._pinned) this.scrollToBottom()

      const hasNewChildren = mutations.some(m =>
        m.type === "childList" && m.target === this.listTarget && m.addedNodes.length > 0
      )
      if (hasNewChildren) this._sortMessages()
    })
    this.observer.observe(this.listTarget, { childList: true, subtree: true })
  }

  disconnect() {
    this.element.removeEventListener("wheel", this._markUser)
    this.element.removeEventListener("touchmove", this._markUser)
    this.element.removeEventListener("scroll", this._onScroll)
    document.removeEventListener("assistant:response-timeout", this._onTimeout)
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

  _sortMessages() {
    const children = Array.from(this.listTarget.children)
    const sorted = children.slice().sort((a, b) => {
      const aTime = parseInt(a.dataset.createdAt || "0", 10)
      const bTime = parseInt(b.dataset.createdAt || "0", 10)
      return aTime - bTime
    })
    if (sorted.some((el, i) => el !== children[i])) {
      this.observer.disconnect()
      sorted.forEach(el => this.listTarget.appendChild(el))
      this.observer.observe(this.listTarget, { childList: true, subtree: true })
    }
  }
}
