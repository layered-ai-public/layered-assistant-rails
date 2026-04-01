// Incremental markdown rendering for streamed assistant messages.
//
// The server broadcasts raw text chunks via a custom Turbo Stream action
// (append_chunk). This module accumulates those chunks, parses the markdown
// with marked, and patches the DOM. To keep fade-in animations stable, a
// full re-render only happens when the block structure changes; otherwise
// only the last block is patched in place. Unclosed code fences are held
// back until their closing marker arrives. When the stream ends, Turbo
// replaces the element with server-rendered HTML, correcting any
// incremental artefacts.

import "@hotwired/turbo-rails"
import { marked } from "marked"

marked.use({
  gfm: true,
  breaks: false,
  renderer: {
    html: () => "" // Strip raw HTML to match server-side sanitisation
  }
})

const rawContent = new WeakMap()
const renderedBlockCount = new WeakMap()
const pendingRender = new WeakMap()

const TYPING_INDICATOR_HTML =
  '<div class="l-ui-typing-indicator" role="status" aria-label="Assistant is typing">' +
    '<span class="l-ui-typing-indicator__dot"></span>' +
    '<span class="l-ui-typing-indicator__dot"></span>' +
    '<span class="l-ui-typing-indicator__dot"></span>' +
  '</div>'

// Returns text up to (but not including) any trailing unclosed code fence.
// marked can't produce valid output for a half-open fence, so we hold it
// back until the closing marker arrives.
function stripUnclosedFence(text) {
  let fenceMarker = null
  let fenceStart = 0
  let pos = 0

  for (const line of text.split("\n")) {
    const trimmed = line.trimStart()
    if (!fenceMarker && (trimmed.startsWith("```") || trimmed.startsWith("~~~"))) {
      fenceMarker = trimmed.slice(0, 3)
      fenceStart = pos
    } else if (fenceMarker && trimmed.startsWith(fenceMarker) && /^[`~]+\s*$/.test(trimmed)) {
      fenceMarker = null
    }
    pos += line.length + 1
  }

  return fenceMarker ? text.substring(0, fenceStart) : text
}

function render(target) {
  const raw = rawContent.get(target) || ""
  if (!raw) return

  const safe = stripUnclosedFence(raw)
  const html = safe ? marked.parse(safe) : ""

  const temp = document.createElement("div")
  temp.innerHTML = html

  // Remove typing indicator before comparing so it doesn't skew child indices
  target.querySelector(".l-ui-typing-indicator")?.remove()

  const prevCount = renderedBlockCount.get(target) || 0
  const newCount = temp.children.length
  const lastTarget = target.children[newCount - 1]
  const lastTemp = temp.children[newCount - 1]
  const tagMatch = lastTarget?.tagName === lastTemp?.tagName

  if (newCount !== prevCount) {
    // Block count changed - full re-render, fade only new blocks
    target.innerHTML = html
    for (let i = prevCount; i < target.children.length; i++) {
      target.children[i].classList.add("l-ui-token-fade")
    }
    renderedBlockCount.set(target, target.children.length)
  } else if (newCount > 0 && tagMatch) {
    // Same count, same tag - patch the last block in place so earlier
    // nodes (and their fade-in transitions) are preserved
    lastTarget.innerHTML = lastTemp.innerHTML
  } else if (newCount > 0) {
    // Same count but tag changed (e.g. <p> became <table>) - full
    // re-render needed since we can't patch across element types
    target.innerHTML = html
    renderedBlockCount.set(target, target.children.length)
  }

  if (safe.length < raw.length && !target.querySelector(".l-ui-typing-indicator")) {
    target.insertAdjacentHTML("beforeend", TYPING_INDICATOR_HTML)
  }
}

Turbo.StreamActions.enable_composer = function () {
  this.targetElements.forEach((form) => {
    form.setAttribute("data-composer-responding-value", "false")
  })
}

Turbo.StreamActions.append_chunk = function () {
  this.targetElements.forEach((target) => {
    const text = this.templateContent.textContent || ""

    if (!rawContent.has(target)) {
      target.classList.add("l-ui-markdown")
      rawContent.set(target, "")
    }

    rawContent.set(target, rawContent.get(target) + text)

    if (!pendingRender.has(target)) {
      pendingRender.set(target, requestAnimationFrame(() => {
        pendingRender.delete(target)
        render(target)
      }))
    }
  })

  document.dispatchEvent(new CustomEvent("assistant:chunk-received"))
}
