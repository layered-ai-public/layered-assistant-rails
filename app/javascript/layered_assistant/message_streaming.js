import "@hotwired/turbo-rails"
import { marked } from "marked"

// Configure marked for GFM (matching server-side Kramdown GFM input)
marked.use({
  gfm: true,
  breaks: false,
  renderer: {
    html: () => "" // Strip raw HTML blocks to match server-side sanitisation
  }
})

// Per-element state stored off-DOM
const renderTimers = new WeakMap()
const rawContent = new WeakMap()

// Threshold (in chars) of unsettled content before re-showing the indicator
const UNSETTLED_THRESHOLD = 200

const TYPING_INDICATOR_HTML =
  '<div class="l-ui-typing-indicator" role="status" aria-label="Assistant is typing">' +
    '<span class="l-ui-typing-indicator__dot"></span>' +
    '<span class="l-ui-typing-indicator__dot"></span>' +
    '<span class="l-ui-typing-indicator__dot"></span>' +
  '</div>'

// Find the boundary between complete markdown blocks (safe to parse) and
// the in-progress tail that is still being streamed. We split at the last
// blank line, but never inside an unclosed code fence.
function findBlockBoundary(text) {
  const lines = text.split("\n")
  let fenceMarker = null
  let boundary = 0
  let pos = 0

  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trimStart()
    if (!fenceMarker && (trimmed.startsWith("```") || trimmed.startsWith("~~~"))) {
      fenceMarker = trimmed.slice(0, 3)
    } else if (fenceMarker && trimmed.startsWith(fenceMarker) && /^[`~]+\s*$/.test(trimmed)) {
      fenceMarker = null
    }

    pos += lines[i].length + 1

    if (!fenceMarker && lines[i] === "" && i > 0) {
      boundary = pos
    }
  }

  return boundary
}

// Append newly settled markdown blocks to the target element. Only the
// portion between the previous boundary and the current one is parsed and
// inserted, so existing DOM nodes stay intact and there is no flicker.
// Turbo replaces the entire element with server-rendered HTML when the
// stream completes, correcting any incremental rendering artefacts.
function renderMarkdown(target) {
  const raw = rawContent.get(target) || ""
  if (!raw) return

  const boundary = findBlockBoundary(raw)
  // No settled blocks yet - the server-rendered typing indicator is still
  // in the DOM, so there's nothing to do until a blank line arrives.
  if (boundary === 0) return

  const previousBoundary = parseInt(target.dataset.settledBoundary || "0", 10)

  if (boundary > previousBoundary) {
    target.dataset.settledBoundary = boundary

    // Remove typing indicator before appending new content
    target.querySelector(".l-ui-typing-indicator")?.remove()

    // Parse and append only the new settled portion
    const prevCount = target.children.length
    target.insertAdjacentHTML("beforeend", marked.parse(raw.substring(previousBoundary, boundary)))

    // Stagger fade-in on newly appended blocks
    for (let i = prevCount; i < target.children.length; i++) {
      target.children[i].style.animationDelay = `${(i - prevCount) * 120}ms`
      target.children[i].classList.add("l-ui-token-fade")
    }
  }

  // Show typing indicator when there's a large unsettled tail, so the user
  // knows content is still arriving (e.g. a long code block before the
  // closing fence). The indicator is removed automatically when the boundary
  // next advances (above).
  const tail = raw.length - boundary
  if (tail >= UNSETTLED_THRESHOLD && !target.querySelector(".l-ui-typing-indicator")) {
    target.insertAdjacentHTML("beforeend", TYPING_INDICATOR_HTML)
  }
}

function scheduleRender(target) {
  const existing = renderTimers.get(target)
  if (existing) cancelAnimationFrame(existing)

  const id = requestAnimationFrame(() => {
    renderTimers.delete(target)
    renderMarkdown(target)
  })
  renderTimers.set(target, id)
}

Turbo.StreamActions.append_chunk = function () {
  this.targetElements.forEach((target) => {
    const text = this.templateContent.textContent || ""

    // Initialise on first chunk
    if (!rawContent.has(target)) {
      target.classList.add("l-ui-markdown")
      rawContent.set(target, "")
    }

    // Accumulate raw markdown off-DOM
    rawContent.set(target, rawContent.get(target) + text)

    // Schedule debounced render
    scheduleRender(target)
  })
}
