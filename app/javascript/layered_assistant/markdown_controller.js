import { Controller } from "@hotwired/stimulus"
import { renderMarkdown } from "layered_assistant/marked_setup"

// Renders raw markdown (placed in the element by the server) as HTML
// on connect. Streaming chunks bypass this and write innerHTML
// directly via Turbo stream actions.

export default class extends Controller {
  connect() {
    const text = this.element.textContent.trim()
    if (!text) return
    this.element.innerHTML = renderMarkdown(text)
  }
}
