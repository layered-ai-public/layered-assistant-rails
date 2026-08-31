require "test_helper"

module Layered
  module Assistant
    class MessagesServiceTest < ActiveSupport::TestCase
      setup do
        @conversation = layered_assistant_conversations(:greeting)
        @service = MessagesService.new
      end

      # Anthropic format (default)

      test "formats user and assistant messages for Anthropic" do
        result = @service.format(@conversation.messages)

        assert_equal 2, result[:messages].size
        assert_equal "user", result[:messages].first[:role]
        assert_equal "Hello there", result[:messages].first[:content].first[:text]
        assert_equal "assistant", result[:messages].second[:role]
      end

      test "skips assistant messages with blank content for Anthropic" do
        @conversation.messages.create!(role: :assistant, content: nil)

        result = @service.format(@conversation.messages)
        assert result[:messages].none? { |m| m[:role] == "assistant" && m[:content].first[:text].blank? }
      end

      test "extracts system messages into system key for Anthropic" do
        @conversation.messages.create!(role: :system, content: "You are helpful.")

        result = @service.format(@conversation.messages)
        assert_equal "You are helpful.", result[:system]
      end

      test "joins multiple system messages for Anthropic" do
        @conversation.messages.create!(role: :system, content: "Be concise.", created_at: 10.minutes.ago)
        @conversation.messages.create!(role: :system, content: "Be helpful.", created_at: 9.minutes.ago)

        result = @service.format(@conversation.messages)
        assert_equal "Be concise.\n\nBe helpful.", result[:system]
      end

      test "omits system key when no system messages for Anthropic" do
        result = @service.format(@conversation.messages)
        assert_nil result[:system]
      end

      test "handles single system message for Anthropic" do
        @conversation.messages.create!(role: :system, content: "You are a helpful assistant.")

        result = @service.format(@conversation.messages)
        assert_equal "You are a helpful assistant.", result[:system]
      end

      # OpenAI format

      test "formats user and assistant messages as strings for OpenAI" do
        provider = layered_assistant_providers(:openai)
        result = @service.format(@conversation.messages, provider: provider)

        assert_equal 2, result[:messages].size
        assert_equal "user", result[:messages].first[:role]
        assert_equal "Hello there", result[:messages].first[:content]
        assert_equal "assistant", result[:messages].second[:role]
        assert_equal "Hi! How can I help?", result[:messages].second[:content]
      end

      test "skips assistant messages with blank content for OpenAI" do
        provider = layered_assistant_providers(:openai)
        @conversation.messages.create!(role: :assistant, content: nil)

        result = @service.format(@conversation.messages, provider: provider)
        assert result[:messages].none? { |m| m[:role] == "assistant" && m[:content].blank? }
      end

      test "includes system messages inline for OpenAI" do
        provider = layered_assistant_providers(:openai)
        @conversation.messages.create!(role: :system, content: "You are helpful.", created_at: 10.minutes.ago)

        result = @service.format(@conversation.messages, provider: provider)

        system_msg = result[:messages].find { |m| m[:role] == "system" }
        assert_not_nil system_msg
        assert_equal "You are helpful.", system_msg[:content]
        assert_nil result[:system]
      end

      test "handles single system message for OpenAI" do
        provider = layered_assistant_providers(:openai)
        @conversation.messages.create!(role: :system, content: "You are a helpful assistant.", created_at: 10.minutes.ago)

        result = @service.format(@conversation.messages, provider: provider)

        system_messages = result[:messages].select { |m| m[:role] == "system" }
        assert_equal 1, system_messages.size
        assert_equal "You are a helpful assistant.", system_messages.first[:content]
      end

      # Tool calls

      test "an assistant message with tool calls becomes a tool_use block for Anthropic" do
        conversation = layered_assistant_conversations(:empty)
        conversation.messages.create!(role: :user, content: "What time is it?")
        conversation.messages.create!(role: :assistant, content: nil, tool_calls: [ tool_call ])

        result = @service.format(conversation.messages)
        blocks = result[:messages].last[:content]

        assert_equal "assistant", result[:messages].last[:role]
        assert_equal [ { type: "tool_use", id: "call_1", name: "lookup", input: { "term" => "rails" } } ], blocks
      end

      test "text alongside tool calls keeps both blocks for Anthropic" do
        conversation = layered_assistant_conversations(:empty)
        conversation.messages.create!(role: :assistant, content: "Let me look.", tool_calls: [ tool_call ])

        blocks = @service.format(conversation.messages)[:messages].last[:content]

        assert_equal [ "text", "tool_use" ], blocks.map { |block| block[:type] }
      end

      test "tool results become a following user message for Anthropic" do
        conversation = layered_assistant_conversations(:empty)
        conversation.messages.create!(role: :assistant, content: nil, tool_calls: [ tool_call ])
        conversation.messages.create!(role: :tool, content: "Found it", tool_call_id: "call_1", tool_name: "lookup")

        result = @service.format(conversation.messages)

        assert_equal "user", result[:messages].last[:role]
        assert_equal [ { type: "tool_result", tool_use_id: "call_1", content: "Found it" } ], result[:messages].last[:content]
      end

      test "consecutive tool results are merged into one user message for Anthropic" do
        conversation = layered_assistant_conversations(:empty)
        conversation.messages.create!(role: :assistant, content: nil, tool_calls: [ tool_call, tool_call("call_2") ])
        conversation.messages.create!(role: :tool, content: "First", tool_call_id: "call_1", tool_name: "lookup")
        conversation.messages.create!(role: :tool, content: "Second", tool_call_id: "call_2", tool_name: "lookup")

        result = @service.format(conversation.messages)

        assert_equal 2, result[:messages].size
        assert_equal [ "call_1", "call_2" ], result[:messages].last[:content].map { |block| block[:tool_use_id] }
      end

      test "an assistant message with tool calls carries them for OpenAI" do
        conversation = layered_assistant_conversations(:empty)
        conversation.messages.create!(role: :assistant, content: nil, tool_calls: [ tool_call ])
        conversation.messages.create!(role: :tool, content: "Found it", tool_call_id: "call_1", tool_name: "lookup")

        result = @service.format(conversation.messages, provider: layered_assistant_providers(:openai))

        assert_equal [ tool_call ], result[:messages].first[:tool_calls]
        assert_equal({ role: "tool", tool_call_id: "call_1", content: "Found it" }, result[:messages].last)
      end

      test "an assistant message that is still streaming is left out" do
        conversation = layered_assistant_conversations(:empty)
        conversation.messages.create!(role: :assistant, content: nil)

        assert_empty @service.format(conversation.messages)[:messages]
        assert_empty @service.format(conversation.messages, provider: layered_assistant_providers(:openai))[:messages]
      end

      private

      def tool_call(id = "call_1")
        {
          "id" => id,
          "type" => "function",
          "function" => { "name" => "lookup", "arguments" => '{"term":"rails"}' }
        }
      end
    end
  end
end
