// Streaming render for assistant messages.
//
// The server broadcasts pre-rendered HTML containing only fully-closed
// top-level markdown blocks, optionally followed by a typing indicator
// for the in-progress block. The client appends new closed blocks with
// a fade-in and keeps a single trailing typing indicator while the
// next block is being typed.

import "@hotwired/turbo-rails"

const pendingHtml = new WeakMap()
const pendingRender = new WeakMap()

function syncStream(target, html) {
  const temp = document.createElement("div")
  temp.innerHTML = html
  const incoming = [...temp.children]

  const lastIsIndicator =
    incoming[incoming.length - 1]?.classList.contains("l-ui-typing-indicator")
  const newIndicator = lastIsIndicator ? incoming.pop() : null

  // Keep the existing indicator in place across broadcasts so its
  // animation doesn't restart on every chunk.
  const existingIndicator = target.querySelector(":scope > .l-ui-typing-indicator")
  const existingClosedCount = target.children.length - (existingIndicator ? 1 : 0)

  // Closed blocks are immutable across broadcasts, so this is purely
  // additive. Insert before the indicator if one's already there.
  for (let i = existingClosedCount; i < incoming.length; i++) {
    incoming[i].classList.add("l-ui-stream-fade")
    if (existingIndicator) {
      target.insertBefore(incoming[i], existingIndicator)
    } else {
      target.appendChild(incoming[i])
    }
  }

  // Only add an indicator if one isn't already there. Don't replace or
  // remove the existing one - that would restart its animation, and
  // broadcast_updated re-renders the whole partial when the response
  // completes.
  if (newIndicator && !existingIndicator) {
    target.appendChild(newIndicator)
  }
}

Turbo.StreamActions.enable_composer = function () {
  this.targetElements.forEach((form) => {
    form.setAttribute("data-composer-responding-value", "false")
  })
}

Turbo.StreamActions.render_content = function () {
  this.targetElements.forEach((target) => {
    if (!target.classList.contains("l-ui-markdown")) {
      target.classList.add("l-ui-markdown")
    }

    // Stash the latest HTML; coalesce multiple chunks per frame.
    const div = document.createElement("div")
    div.append(this.templateContent.cloneNode(true))
    pendingHtml.set(target, div.innerHTML)

    if (!pendingRender.has(target)) {
      pendingRender.set(target, requestAnimationFrame(() => {
        pendingRender.delete(target)
        const latestHtml = pendingHtml.get(target)
        if (latestHtml != null) {
          syncStream(target, latestHtml)
          pendingHtml.delete(target)
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
