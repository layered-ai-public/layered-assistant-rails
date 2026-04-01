require "test_helper"

module Layered
  module Assistant
    class MessagesHelperTest < ActionView::TestCase
      include MessagesHelper

      private

      def build_message(role:, content:)
        Message.new(role: role, content: content, conversation: layered_assistant_conversations(:greeting))
      end

      public

      # --- Assistant markdown rendering ---

      test "renders paragraphs for assistant messages" do
        message = build_message(role: :assistant, content: "Hello world")
        result = render_message_content(message)
        assert_includes result, "<p>Hello world</p>"
      end

      test "renders bold text" do
        message = build_message(role: :assistant, content: "This is **bold** text")
        result = render_message_content(message)
        assert_includes result, "<strong>bold</strong>"
      end

      test "renders italic text" do
        message = build_message(role: :assistant, content: "This is *italic* text")
        result = render_message_content(message)
        assert_includes result, "<em>italic</em>"
      end

      test "renders strikethrough text" do
        message = build_message(role: :assistant, content: "This is ~~deleted~~ text")
        result = render_message_content(message)
        assert_includes result, "<del>deleted</del>"
      end

      test "renders inline code" do
        message = build_message(role: :assistant, content: "Use `puts` to print")
        result = render_message_content(message)
        assert_includes result, "<code>puts</code>"
      end

      test "renders code blocks" do
        message = build_message(role: :assistant, content: "```ruby\nputs 'hello'\n```")
        result = render_message_content(message)
        assert_includes result, "<pre><code"
        assert_includes result, "puts 'hello'"
      end

      test "renders unordered lists" do
        message = build_message(role: :assistant, content: "- one\n- two\n- three")
        result = render_message_content(message)
        assert_includes result, "<ul>"
        assert_includes result, "<li>one</li>"
      end

      test "renders ordered lists" do
        message = build_message(role: :assistant, content: "1. first\n2. second")
        result = render_message_content(message)
        assert_includes result, "<ol>"
        assert_includes result, "<li>first</li>"
      end

      test "renders headings" do
        message = build_message(role: :assistant, content: "# Heading 1\n## Heading 2\n### Heading 3")
        result = render_message_content(message)
        assert_includes result, "<h1"
        assert_includes result, "<h2"
        assert_includes result, "<h3"
      end

      test "renders links" do
        message = build_message(role: :assistant, content: "[Example](https://example.com)")
        result = render_message_content(message)
        assert_includes result, '<a href="https://example.com"'
        assert_includes result, "Example</a>"
      end

      test "renders blockquotes" do
        message = build_message(role: :assistant, content: "> This is a quote")
        result = render_message_content(message)
        assert_includes result, "<blockquote>"
      end

      test "renders tables" do
        markdown = "| Name | Age |\n|------|-----|\n| Alice | 30 |"
        message = build_message(role: :assistant, content: markdown)
        result = render_message_content(message)
        assert_includes result, "<table>"
        assert_includes result, "<th>Name</th>"
        assert_includes result, "<td>Alice</td>"
      end

      test "renders tables immediately after headings" do
        markdown = "## Results\n| Name | Age |\n|------|-----|\n| Alice | 30 |"
        message = build_message(role: :assistant, content: markdown)
        result = render_message_content(message)
        assert_includes result, "<table>"
        assert_includes result, "<th>Name</th>"
      end

      test "renders tables immediately after paragraphs" do
        markdown = "Here are the results:\n| Name | Age |\n|------|-----|\n| Alice | 30 |"
        message = build_message(role: :assistant, content: markdown)
        result = render_message_content(message)
        assert_includes result, "<table>"
        assert_includes result, "<th>Name</th>"
      end

      test "renders horizontal rules" do
        message = build_message(role: :assistant, content: "Above\n\n---\n\nBelow")
        result = render_message_content(message)
        assert_includes result, "<hr"
      end

      test "returns html_safe string for assistant messages" do
        message = build_message(role: :assistant, content: "Hello")
        result = render_message_content(message)
        assert result.html_safe?
      end

      # --- XSS sanitization ---

      test "strips script tags" do
        message = build_message(role: :assistant, content: "<script>alert('xss')</script>")
        result = render_message_content(message)
        assert_not_includes result, "<script>"
        assert_not_includes result, "</script>"
      end

      test "strips onclick attributes" do
        message = build_message(role: :assistant, content: '<a href="#" onclick="alert(1)">click</a>')
        result = render_message_content(message)
        assert_not_includes result, "onclick"
      end

      test "strips iframe tags" do
        message = build_message(role: :assistant, content: '<iframe src="https://evil.com"></iframe>')
        result = render_message_content(message)
        assert_not_includes result, "<iframe"
      end

      # --- User messages ---

      test "renders markdown in user messages" do
        message = build_message(role: :user, content: "Hello **world**")
        result = render_message_content(message)
        assert_includes result, "<strong>world</strong>"
      end

      test "sanitizes HTML in user messages" do
        message = build_message(role: :user, content: "<script>alert('xss')</script>")
        result = render_message_content(message)
        assert_not_includes result, "<script>"
      end

      test "preserves newlines in user messages" do
        message = build_message(role: :user, content: "line one\n\nline two")
        result = render_message_content(message)
        assert_includes result, "<p>"
      end

      # --- Markdown fence stripping ---

      test "strips outer markdown fence wrapper" do
        markdown = "```markdown\n# Hello\n\nWorld\n```"
        message = build_message(role: :assistant, content: markdown)
        result = render_message_content(message)
        assert_includes result, "<h1"
        assert_includes result, "Hello"
        assert_not_includes result, "```markdown"
      end

      test "renders table inside markdown fence wrapper" do
        markdown = "```markdown\n| Name | Age |\n|------|-----|\n| Alice | 30 |\n```"
        message = build_message(role: :assistant, content: markdown)
        result = render_message_content(message)
        assert_includes result, "<table>"
        assert_includes result, "<th>Name</th>"
        assert_includes result, "<td>Alice</td>"
      end

      test "does not strip non-markdown code fences" do
        markdown = "```ruby\nputs 'hello'\n```"
        message = build_message(role: :assistant, content: markdown)
        result = render_message_content(message)
        assert_includes result, "<pre><code"
        assert_includes result, "puts 'hello'"
      end

      test "does not strip markdown fence that is not the outer wrapper" do
        markdown = "Some text\n\n```markdown\n# Hello\n```"
        message = build_message(role: :assistant, content: markdown)
        result = render_message_content(message)
        assert_includes result, "<pre><code"
      end

      # --- message_metadata_title ---

      test "metadata title includes token count" do
        message = build_message(role: :assistant, content: "Hi")
        message.input_tokens = 100
        message.output_tokens = 50
        assert_includes message_metadata_title(message), "150 tokens"
      end

      test "metadata title shows estimated prefix" do
        message = build_message(role: :assistant, content: "Hi")
        message.output_tokens = 10
        message.tokens_estimated = true
        assert_includes message_metadata_title(message), "~10 tokens"
      end

      test "metadata title includes TTFT" do
        message = build_message(role: :assistant, content: "Hi")
        message.ttft_ms = 250
        assert_includes message_metadata_title(message), "250ms TTFT"
      end

      test "metadata title includes tok/s" do
        message = build_message(role: :assistant, content: "Hi")
        message.output_tokens = 100
        message.response_ms = 2000
        assert_includes message_metadata_title(message), "50.0 tok/s"
      end

      test "metadata title omits tok/s when response_ms is below threshold" do
        message = build_message(role: :assistant, content: "Hi")
        message.output_tokens = 100
        message.response_ms = 50
        assert_not_includes message_metadata_title(message), "tok/s"
      end

      test "metadata title returns empty string with no data" do
        message = build_message(role: :user, content: "Hi")
        assert_equal "", message_metadata_title(message)
      end

      test "metadata title joins parts with separator" do
        message = build_message(role: :assistant, content: "Hi")
        message.input_tokens = 100
        message.output_tokens = 50
        message.ttft_ms = 200
        result = message_metadata_title(message)
        assert_includes result, "150 tokens"
        assert_includes result, " · "
        assert_includes result, "200ms TTFT"
      end

      # --- Edge cases ---

      test "returns nil for blank content" do
        message = build_message(role: :assistant, content: "")
        assert_nil render_message_content(message)
      end

      test "returns nil for nil content" do
        message = build_message(role: :assistant, content: nil)
        assert_nil render_message_content(message)
      end
    end
  end
end
