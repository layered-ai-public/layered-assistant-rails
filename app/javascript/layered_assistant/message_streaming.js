// Streaming render for assistant messages.
//
// The server broadcasts the raw markdown content as it grows; the
// client parses it with marked and replaces the message body. A
// typing indicator is appended while streaming. Renders are
// coalesced per animation frame.

import "@hotwired/turbo-rails"
import { marked } from "marked"

marked.use({ gfm: true, breaks: false })

const TYPING_INDICATOR = '<div class="l-ui-typing-indicator" role="status" aria-label="Assistant is typing"><span class="l-ui-typing-indicator__dot"></span><span class="l-ui-typing-indicator__dot"></span><span class="l-ui-typing-indicator__dot"></span></div>'

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
    target.classList.add("l-ui-markdown")
    pendingMarkdown.set(target, markdown)

    if (!pendingRender.has(target)) {
      pendingRender.set(target, requestAnimationFrame(() => {
        pendingRender.delete(target)
        const md = pendingMarkdown.get(target)
        if (md != null) {
          target.innerHTML = marked.parse(md) + TYPING_INDICATOR
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
