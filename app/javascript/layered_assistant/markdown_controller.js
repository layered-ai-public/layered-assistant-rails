import { Controller } from "@hotwired/stimulus"
import { renderMarkdown } from "layered_assistant/marked_setup"

// Renders raw markdown (placed in the element by the server) as HTML
// on connect. Streaming chunks bypass this and write innerHTML
// directly via Turbo stream actions.

export default class extends Controller {
  connect() {
    // Skip if the element already contains rendered HTML - e.g. Turbo
    // Drive cache restore, or streaming output appended by the message
    // stream actions. textContent would flatten rendered HTML back to
    // plain text and marked would silently drop all formatting.
    if (this.element.firstElementChild) return
    const text = this.element.textContent.trim()
    if (!text) return
    this.element.innerHTML = renderMarkdown(text)
  }
}
