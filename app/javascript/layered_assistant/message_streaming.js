// Incremental markdown rendering for streamed assistant messages.
//
// The server broadcasts pre-rendered HTML via a custom Turbo Stream action
// (render_content). This module reconciles the DOM block by block -
// patching unchanged blocks in place so fade-in animations aren't
// interrupted. Both streaming preview and final output use the same
// server-side Kramdown pipeline, eliminating parser drift.

import "@hotwired/turbo-rails"

const pendingHtml = new WeakMap()
const pendingRender = new WeakMap()

function reconcile(target, html) {
  const temp = document.createElement("div")
  temp.innerHTML = html

  // Snapshot temp.children since moves will mutate the live HTMLCollection
  const newBlocks = [...temp.children]

  // Trim excess blocks from previous render
  while (target.children.length > newBlocks.length) {
    target.lastElementChild.remove()
  }

  // Reconcile block by block - preserves existing DOM nodes (and their
  // running fade-in animations) wherever possible
  for (let i = 0; i < newBlocks.length; i++) {
    if (i < target.children.length && target.children[i].tagName === newBlocks[i].tagName) {
      // Same tag - patch content in place
      if (target.children[i].innerHTML !== newBlocks[i].innerHTML) {
        target.children[i].innerHTML = newBlocks[i].innerHTML
      }
    } else if (i < target.children.length) {
      // Tag changed (e.g. <p> became <table>) - replace node
      target.children[i].replaceWith(newBlocks[i])
    } else {
      // New block - append with fade
      newBlocks[i].classList.add("l-ui-token-fade")
      target.appendChild(newBlocks[i])
    }
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

    const html = this.templateContent

    // Always store the latest HTML so the requestAnimationFrame callback
    // uses the newest version - convert DocumentFragment to HTML string
    const div = document.createElement("div")
    div.append(html.cloneNode(true))
    pendingHtml.set(target, div.innerHTML)

    if (!pendingRender.has(target)) {
      pendingRender.set(target, requestAnimationFrame(() => {
        pendingRender.delete(target)
        const latestHtml = pendingHtml.get(target)
        if (latestHtml != null) {
          reconcile(target, latestHtml)
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
  if (oldName && document.title.startsWith(oldName)) {
    document.title = document.title.replace(oldName, name)
  }
}
