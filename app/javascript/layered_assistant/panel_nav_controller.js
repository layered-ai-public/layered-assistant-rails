import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  navigate(event) {
    const value = event.target.value
    const frame = document.getElementById("assistant_panel")
    if (!frame) return

    if (value === "new") {
      const url = event.target.dataset.panelNavNewUrlValue
      frame.src = url
    } else {
      frame.src = value
    }
  }
}
