// Streaming render for assistant messages.
//
// The server broadcasts the raw markdown content as it grows; the
// client parses it with marked and appends newly-closed top-level
// blocks to the message content element with a fade. The trailing
// block is always held back - even when it's already complete - so
// we don't fade-restart it on every chunk; the typing indicator
// sibling covers for it visually. Trade-off: single-block responses
// stay hidden until broadcast_response_complete swaps in the final
// partial. Acceptable because the swap is near-instant and the
// indicator masks the gap.

import "@hotwired/turbo-rails"
import { renderMarkdown } from "layered_assistant/marked_setup"

const pendingMarkdown = new WeakMap()
const pendingRender = new WeakMap()

Turbo.StreamActions.enable_composer = function () {
  this.targetElements.forEach((form) => {
    form.setAttribute("data-composer-responding-value", "false")
  })
}

function syncStreamingContent(target, markdown) {
  const tmp = document.createElement("div")
  tmp.innerHTML = renderMarkdown(markdown)
  const incoming = [...tmp.children]
  // Hold back the trailing in-progress block; only append new closed ones.
  const closedCount = Math.max(0, incoming.length - 1)
  for (let i = target.children.length; i < closedCount; i++) {
    incoming[i].classList.add("l-ui-stream-fade")
    target.appendChild(incoming[i])
  }
  if (target.children.length > 0) {
    const indicator = target.parentElement?.querySelector(".l-ui-typing-indicator")
    indicator?.classList.add("l-ui-mt-4")
  }
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
          syncStreamingContent(target, md)
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
