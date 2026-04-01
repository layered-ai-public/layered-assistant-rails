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

        markdown = unwrap_markdown_fence(message.content)
        markdown = ensure_blank_line_before_tables(markdown)

        html = Kramdown::Document.new(
          markdown,
          input: "GFM",
          syntax_highlighter: nil
        ).to_html

        sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)
      end

      private

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
    end
  end
end
