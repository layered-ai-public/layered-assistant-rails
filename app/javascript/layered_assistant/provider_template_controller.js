import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["name", "protocol", "url", "description", "secretHint"]

  static values = {
    templates: Array
  }

  apply(event) {
    const key = event.target.value
    if (!key) return

    const template = this.templatesValue.find((t) => t.key === key)
    if (!template) return

    this.nameTarget.value = template.name
    this.protocolTarget.value = template.protocol
    this.urlTarget.value = template.url || ""
    this.updateDescription(template)
    this.updateSecretHint(template)
  }

  updateDescription(template) {
    if (!this.hasDescriptionTarget) return

    if (template.description) {
      this.descriptionTarget.textContent = template.description
      this.descriptionTarget.hidden = false
    } else {
      this.descriptionTarget.hidden = true
    }
  }

  updateSecretHint(template) {
    if (!this.hasSecretHintTarget) return

    if (template.keys_url) {
      this.secretHintTarget.innerHTML = `Get your key from: <a href="${template.keys_url}" target="_blank" rel="noopener noreferrer">${template.keys_url}</a>`
      this.secretHintTarget.hidden = false
    } else {
      this.secretHintTarget.hidden = true
    }
  }
}
