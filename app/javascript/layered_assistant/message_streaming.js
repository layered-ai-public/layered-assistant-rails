// Streaming render for assistant messages.
//
// The server broadcasts the raw markdown content as it grows; the
// client parses it with marked and replaces the message content
// element. The typing indicator lives as a sibling and is left alone
// across chunks so its CSS animation never restarts. It's removed
// when the partial is replaced after streaming completes or stops.

import "@hotwired/turbo-rails"
import { renderMarkdown } from "layered_assistant/marked_setup"

const pendingMarkdown = new WeakMap()
const pendingRender = new WeakMap()

Turbo.StreamActions.enable_composer = function () {
  this.targetElements.forEach((form) => {
    form.setAttribute("data-composer-responding-value", "false")
  })
}

Turbo.StreamActions.render_content = function () {
  const markdown = this.templateContent.textContent

  this.targetElements.forEach((target) => {
    pendingMarkdown.set(target, markdown)

    if (!pendingRender.has(target)) {
      pendingRender.set(target, requestAnimationFrame(() => {
        pendingRender.delete(target)
        const md = pendingMarkdown.get(target)
        if (md != null) {
          target.innerHTML = renderMarkdown(md)
          pendingMarkdown.delete(target)
        }
      }))
    }
  })

  document.dispatchEvent(new CustomEvent("assistant:chunk-received"))
}

Turbo.StreamActions.update_conversation_name = function () {
  const name = this.getAttribute("name")
  const oldName = this.getAttribute("old-name")
  this.targetElements.forEach((el) => { el.textContent = name })
  if (oldName && document.title.includes(oldName)) {
    const i = document.title.indexOf(oldName)
    document.title = document.title.slice(0, i) + name + document.title.slice(i + oldName.length)
  }
}
