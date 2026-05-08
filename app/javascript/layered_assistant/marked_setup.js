// Markdown rendering pipeline.
//
// Raw HTML in the markdown source is dropped at the marked tokenizer
// level so LLM output can't smuggle <script> or other tags. Marked
// output is then run through DOMPurify, which validates URL schemes
// (blocking javascript:, data:, vbscript: in href/src) and strips
// any unsafe attributes that slipped through.

import { marked } from "marked"
import DOMPurify from "dompurify"

marked.use({
  gfm: true,
  breaks: false,
  tokenizer: {
    html() { return false },
    tag() { return false }
  }
})

export function renderMarkdown(text) {
  if (!text) return ""
  return DOMPurify.sanitize(marked.parse(text))
}
