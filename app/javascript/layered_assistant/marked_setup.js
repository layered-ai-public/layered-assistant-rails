// Markdown rendering pipeline.
//
// Marked parses LLM output (including any raw HTML it emits), then
// DOMPurify sanitises the result: it strips <script> and other unsafe
// tags, validates URL schemes (blocking javascript:, data:, vbscript:
// in href/src), and removes unsafe attributes. DOMPurify is the sole
// security boundary here.

import { marked } from "marked"
import DOMPurify from "dompurify"

marked.use({
  gfm: true,
  breaks: false
})

export function renderMarkdown(text) {
  if (!text) return ""
  return DOMPurify.sanitize(marked.parse(text))
}
