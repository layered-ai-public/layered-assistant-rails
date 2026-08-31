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

      # --- message_model_label ---

      test "model label is the model name when no resolved model is recorded" do
        message = build_message(role: :assistant, content: "Hi")
        message.model = layered_assistant_models(:sonnet)
        assert_equal message.model.name, message_model_label(message)
      end

      test "model label is the model name when the resolved model matches" do
        message = build_message(role: :assistant, content: "Hi")
        message.model = layered_assistant_models(:sonnet)
        message.resolved_model = message.model.identifier
        assert_equal message.model.name, message_model_label(message)
      end

      test "model label is the model name when the resolved model differs only by case" do
        message = build_message(role: :assistant, content: "Hi")
        message.model = layered_assistant_models(:sonnet)
        message.resolved_model = message.model.identifier.upcase
        assert_equal message.model.name, message_model_label(message)
      end

      test "model label names both models when the resolved model differs" do
        message = build_message(role: :assistant, content: "Hi")
        message.model = layered_assistant_models(:sonnet)
        message.resolved_model = "z-ai/glm-5.2"
        assert_equal "#{message.model.name} · z-ai/glm-5.2", message_model_label(message)
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

      # --- message_tool_request? ---

      test "an assistant message that only asked for tools is a tool request" do
        message = build_message(role: :assistant, content: nil)
        message.tool_calls = [ { "id" => "call_1", "function" => { "name" => "lookup" } } ]

        assert message_tool_request?(message)
      end

      test "an assistant message with text is not a tool request, even alongside tool calls" do
        message = build_message(role: :assistant, content: "Let me look.")
        message.tool_calls = [ { "id" => "call_1", "function" => { "name" => "lookup" } } ]

        assert_not message_tool_request?(message)
      end

      test "a streaming assistant message is not a tool request" do
        assert_not message_tool_request?(build_message(role: :assistant, content: nil))
      end

      # --- tool_payload ---

      test "tool payload pretty-prints JSON" do
        assert_equal "{\n  \"term\": \"rails\"\n}", tool_payload('{"term":"rails"}')
      end

      test "tool payload passes through what is not JSON" do
        assert_equal "not json at all", tool_payload("not json at all")
      end

      test "tool payload is empty for a blank payload" do
        assert_equal "", tool_payload(nil)
      end
    end
  end
end
