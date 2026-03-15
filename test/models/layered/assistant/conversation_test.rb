require "test_helper"

module Layered
  module Assistant
    class ConversationTest < ActiveSupport::TestCase
      test "default_name returns placeholder" do
        assert_equal "New conversation", Conversation.default_name
      end

      test "update_name_from_content! sets name from first message" do
        assistant = layered_assistant_assistants(:general)
        conversation = Conversation.create!(name: Conversation.default_name, assistant: assistant)

        conversation.update_name_from_content!("How do I write a Rails engine?")
        assert_equal "How do I write a Rails engine?", conversation.name
      end

      test "update_name_from_content! truncates long content" do
        assistant = layered_assistant_assistants(:general)
        conversation = Conversation.create!(name: Conversation.default_name, assistant: assistant)

        conversation.update_name_from_content!("a" * 100)
        assert_equal 60, conversation.name.length
        assert conversation.name.end_with?("...")
      end

      test "update_name_from_content! does not overwrite a custom name" do
        assistant = layered_assistant_assistants(:general)
        conversation = Conversation.create!(name: "My custom name", assistant: assistant)

        conversation.update_name_from_content!("Some message")
        assert_equal "My custom name", conversation.name
      end

      test "update_name_from_content! ignores blank content" do
        assistant = layered_assistant_assistants(:general)
        conversation = Conversation.create!(name: Conversation.default_name, assistant: assistant)

        conversation.update_name_from_content!("")
        assert_equal "New conversation", conversation.name
      end

      test "update_token_totals! sums input and output tokens separately" do
        assistant = layered_assistant_assistants(:general)
        conversation = Conversation.create!(name: "Token Test", assistant: assistant)
        conversation.messages.create!(role: :user, content: "Hello", input_tokens: 10)
        conversation.messages.create!(role: :assistant, content: "Hi there", input_tokens: 50, output_tokens: 25)

        conversation.update_token_totals!
        conversation.reload
        assert_equal 60, conversation.input_tokens
        assert_equal 25, conversation.output_tokens
        assert_equal 85, conversation.token_estimate
      end

      test "stop_response! marks latest assistant message as stopped" do
        conversation = layered_assistant_conversations(:greeting)
        assistant_message = conversation.messages.create!(role: :assistant, content: "Partial", model: layered_assistant_models(:sonnet))

        assert conversation.stop_response!

        assert assistant_message.reload.stopped?
      end

      test "stop_response! sets output_tokens to zero when content is blank" do
        conversation = layered_assistant_conversations(:greeting)
        assistant_message = conversation.messages.create!(role: :assistant, content: nil, model: layered_assistant_models(:sonnet))

        conversation.stop_response!

        assistant_message.reload
        assert assistant_message.stopped?
        assert_equal 0, assistant_message.output_tokens
        assert assistant_message.tokens_estimated?
      end

      test "stop_response! returns false when no assistant message exists" do
        assistant = layered_assistant_assistants(:general)
        conversation = Conversation.create!(name: "Empty", assistant: assistant)

        assert_equal false, conversation.stop_response!
      end

      test "stop_response! is idempotent" do
        assistant = layered_assistant_assistants(:general)
        conversation = Conversation.create!(name: "Idempotent", assistant: assistant)
        message = conversation.messages.create!(role: :assistant, content: "Partial", model: layered_assistant_models(:sonnet))

        assert_equal true, conversation.stop_response!
        assert message.reload.stopped?

        assert_equal false, conversation.stop_response!
      end

      test "update_token_totals! treats nil tokens as zero" do
        assistant = layered_assistant_assistants(:general)
        conversation = Conversation.create!(name: "Token Test Nil", assistant: assistant)
        conversation.messages.create!(role: :user, content: "Hello", input_tokens: 10)
        conversation.messages.create!(role: :assistant, content: "Hi", input_tokens: nil, output_tokens: nil)

        conversation.update_token_totals!
        conversation.reload
        assert_equal 10, conversation.input_tokens
        assert_equal 0, conversation.output_tokens
        assert_equal 10, conversation.token_estimate
      end
    end
  end
end
