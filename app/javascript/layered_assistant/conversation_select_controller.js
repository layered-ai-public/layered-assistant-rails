import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  navigate(event) {
    const value = event.target.value
    if (value) Turbo.visit(value)
  }
}
