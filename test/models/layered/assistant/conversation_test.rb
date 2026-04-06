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

      test "responding? returns true when assistant message has no output_tokens" do
        assistant = layered_assistant_assistants(:general)
        conversation = Conversation.create!(name: "Responding", assistant: assistant)
        conversation.messages.create!(role: :assistant, content: nil, model: layered_assistant_models(:sonnet))

        assert conversation.responding?
      end

      test "responding? returns false when assistant message has output_tokens" do
        assistant = layered_assistant_assistants(:general)
        conversation = Conversation.create!(name: "Done", assistant: assistant)
        conversation.messages.create!(role: :assistant, content: "Done", output_tokens: 10, model: layered_assistant_models(:sonnet))

        assert_not conversation.responding?
      end

      test "responding? returns false when assistant message is stopped" do
        assistant = layered_assistant_assistants(:general)
        conversation = Conversation.create!(name: "Stopped", assistant: assistant)
        conversation.messages.create!(role: :assistant, content: nil, stopped: true, output_tokens: 5, model: layered_assistant_models(:sonnet))

        assert_not conversation.responding?
      end

      test "responding? returns false when no assistant messages exist" do
        assistant = layered_assistant_assistants(:general)
        conversation = Conversation.create!(name: "Empty", assistant: assistant)

        assert_not conversation.responding?
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

      test "stop_response! estimates input_tokens from prior messages when nil" do
        assistant = layered_assistant_assistants(:general)
        conversation = Conversation.create!(name: "Stop Token Test", assistant: assistant)
        conversation.messages.create!(role: :user, content: "Hello there")
        assistant_message = conversation.messages.create!(role: :assistant, content: "Partial response", model: layered_assistant_models(:sonnet))

        assert_nil assistant_message.input_tokens

        conversation.stop_response!
        assistant_message.reload

        assert assistant_message.tokens_estimated?
        assert_not_nil assistant_message.input_tokens
        assert assistant_message.input_tokens > 0
      end

      test "stop_response! does not overwrite input_tokens when already set" do
        assistant = layered_assistant_assistants(:general)
        conversation = Conversation.create!(name: "Stop Token Preserve", assistant: assistant)
        assistant_message = conversation.messages.create!(role: :assistant, content: "Partial", input_tokens: 42, model: layered_assistant_models(:sonnet))

        conversation.stop_response!

        assert_equal 42, assistant_message.reload.input_tokens
      end

      test "stop_response! is idempotent" do
        assistant = layered_assistant_assistants(:general)
        conversation = Conversation.create!(name: "Idempotent", assistant: assistant)
        message = conversation.messages.create!(role: :assistant, content: "Partial", model: layered_assistant_models(:sonnet))

        assert_equal true, conversation.stop_response!
        assert message.reload.stopped?

        assert_equal false, conversation.stop_response!
      end

      test "creates system message from assistant instructions on create" do
        assistant = layered_assistant_assistants(:coding)
        conversation = Conversation.create!(name: "Snapshot test", assistant: assistant)

        system_message = conversation.messages.find_by(role: :system)
        assert_not_nil system_message
        assert_equal assistant.instructions, system_message.content
      end

      test "creates system message combining persona and assistant instructions" do
        assistant = layered_assistant_assistants(:general)
        conversation = Conversation.create!(name: "Persona test", assistant: assistant)

        system_message = conversation.messages.find_by(role: :system)
        assert_not_nil system_message
        expected = "**Persona**\n\n#{assistant.persona.instructions}\n\n#{assistant.instructions}"
        assert_equal expected, system_message.content
      end

      test "system message is not affected by later changes to assistant instructions" do
        assistant = layered_assistant_assistants(:coding)
        conversation = Conversation.create!(name: "Frozen prompt", assistant: assistant)
        original_instructions = assistant.instructions

        assistant.update!(instructions: "Completely different instructions")
        system_message = conversation.messages.find_by(role: :system)
        assert_equal original_instructions, system_message.content
      end

      test "does not create system message when assistant has no instructions and no persona" do
        assistant = layered_assistant_assistants(:coding)
        assistant.update!(instructions: nil)
        conversation = Conversation.create!(name: "No prompt", assistant: assistant)

        assert_nil conversation.messages.find_by(role: :system)
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
