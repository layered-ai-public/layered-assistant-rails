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
    end
  end
end
