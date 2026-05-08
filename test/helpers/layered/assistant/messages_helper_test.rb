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
    end
  end
end
