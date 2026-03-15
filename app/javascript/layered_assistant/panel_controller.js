import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { storageKey: { type: String, default: "assistant_panel_url" } }

  connect() {
    const saved = sessionStorage.getItem(this.storageKeyValue)
    if (saved && saved !== this.element.src) {
      this.element.src = saved
    }

    this.element.addEventListener("turbo:before-fetch-response", this.syncHeader)
    this.element.addEventListener("turbo:frame-load", this.save)
  }

  disconnect() {
    this.element.removeEventListener("turbo:before-fetch-response", this.syncHeader)
    this.element.removeEventListener("turbo:frame-load", this.save)
  }

  save = () => {
    sessionStorage.setItem(this.storageKeyValue, this.element.src)
  }

  syncHeader = async (event) => {
    const response = event.detail.fetchResponse.response
    const html = await response.clone().text()
    const doc = new DOMParser().parseFromString(html, "text/html")
    const newHeader = doc.querySelector("turbo-frame#assistant_panel_header")
    const currentHeader = document.getElementById("assistant_panel_header")

    if (newHeader && currentHeader) {
      currentHeader.innerHTML = newHeader.innerHTML
    }
  }
}
