module Layered
  module Assistant
    module MessagesHelper
      ALLOWED_TAGS = %w[
        p br
        h1 h2 h3 h4 h5 h6
        strong em s del
        ul ol li
        pre code
        a
        blockquote
        table thead tbody tr th td
        hr
      ].freeze

      ALLOWED_ATTRIBUTES = %w[href title class].freeze

      MIN_RESPONSE_MS_FOR_TPS = 100

      def message_metadata_title(message)
        total_tokens = message.input_tokens.to_i + message.output_tokens.to_i
        parts = []
        if total_tokens > 0
          prefix = message.tokens_estimated? ? "~" : ""
          parts << "#{prefix}#{number_with_delimiter(total_tokens)} tokens"
        end
        if message.output_tokens.to_i > 0 && message.response_ms.to_i >= MIN_RESPONSE_MS_FOR_TPS
          tps = (message.output_tokens * 1000.0 / message.response_ms).round(1)
          parts << "#{tps} tok/s"
        end
        parts << "#{message.ttft_ms}ms TTFT" if message.ttft_ms
        parts.join(" · ")
      end

      def render_message_content(message)
        return if message.content.blank?

        render_markdown(message.content)
      end

      # Renders only the fully-closed top-level blocks of a streaming
      # message. The in-progress trailing block is held back so the
      # caller can show a typing indicator in its place, then the whole
      # block fades in when it closes.
      # Returns { html:, in_progress: }.
      def render_streaming_markdown(content)
        return { html: "", in_progress: false } if content.blank?

        closed = closed_block_prefix(content)
        {
          html: closed.present? ? render_markdown(closed) : "",
          in_progress: closed.length < content.length
        }
      end

      private

      def render_markdown(content)
        markdown = unwrap_markdown_fence(content)
        markdown = ensure_blank_line_before_tables(markdown)

        html = Kramdown::Document.new(
          markdown,
          input: "GFM",
          syntax_highlighter: nil
        ).to_html

        sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)
      end

      # Some LLMs wrap their entire response in a ```markdown fence.
      # Strip it so Kramdown processes the inner content directly.
      def unwrap_markdown_fence(content)
        if content.start_with?("```markdown\n") && content.end_with?("\n```")
          content.delete_prefix("```markdown\n").delete_suffix("\n```")
        else
          content
        end
      end

      # Kramdown GFM requires a blank line before a table, but LLMs often
      # place tables directly after headings or paragraphs. Insert one
      # where missing so that Kramdown recognises the table syntax.
      def ensure_blank_line_before_tables(text)
        text.gsub(/([^\n])\n(\|[^\n]+\|\s*\n\|[\s:|-]+\|\s*\n)/, "\\1\n\n\\2")
      end

      # Returns the prefix of text consisting of fully-closed top-level
      # blocks. A block boundary is a blank line outside any open code
      # fence; a closing fence also marks its block as closed. Anything
      # after the last boundary is treated as in-progress and held back.
      def closed_block_prefix(text)
        fence_marker = nil
        last_boundary = 0
        pos = 0

        text.each_line do |line|
          trimmed = line.lstrip
          if fence_marker
            if trimmed.match?(/\A#{Regexp.escape(fence_marker[0])}{#{fence_marker.length},}\s*\z/)
              fence_marker = nil
              last_boundary = pos + line.length
            end
          elsif (match = trimmed.match(/\A(`{3,}|~{3,})/))
            fence_marker = match[1]
          elsif line.strip.empty?
            last_boundary = pos + line.length
          end
          pos += line.length
        end

        text[0, last_boundary]
      end
    end
  end
end
