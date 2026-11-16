import { Controller } from "@hotwired/stimulus"

// Checks a provider's API key as it's typed, through the server (see
// Providers::KeyCheckService), once typing pauses, and badges it: Validated
// when the provider accepts it, Not validated when it refuses it, and
// Couldn't verify when it couldn't be asked or wouldn't say (a restricted
// key, or the provider being down). The server checks again when the form is
// sent, refusing only a key the provider refused.
export default class extends Controller {
  static targets = ["secret", "protocol", "url", "badge"]
  static values = { endpoint: String, delay: { type: Number, default: 600 } }

  disconnect() {
    clearTimeout(this.timer)
    this.request?.abort()
  }

  check() {
    clearTimeout(this.timer)
    this.request?.abort()

    // Nothing to ask until there's a key, and a protocol to say which provider.
    const secret = this.secretTarget.value.trim()
    if (secret === "" || this.protocolTarget.value === "") return this.showBadge()

    this.showBadge("Checking…", "default")
    this.timer = setTimeout(() => this.send(secret), this.delayValue)
  }

  async send(secret) {
    this.request = new AbortController()

    try {
      const response = await fetch(this.endpointValue, {
        method: "POST",
        signal: this.request.signal,
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content
        },
        body: JSON.stringify({ protocol: this.protocolTarget.value, url: this.urlTarget.value, secret })
      })
      if (!response.ok) throw new Error(response.statusText)

      const { status, message } = await response.json()
      if (status === "valid") {
        this.showBadge("Validated", "success", message)
      } else if (status === "invalid") {
        this.showBadge("Not validated", "danger", message)
      } else {
        this.showBadge("Couldn't verify", "warning", message)
      }
    } catch (error) {
      if (error.name !== "AbortError") this.showBadge("Couldn't verify", "warning", "The key couldn't be checked.")
    }
  }

  // No label hides it.
  showBadge(label = "", variant = "default", title = "") {
    this.badgeTarget.hidden = label === ""
    this.badgeTarget.textContent = label
    this.badgeTarget.title = title
    this.badgeTarget.className = `l-ui-badge l-ui-badge--${variant}`
  }
}
