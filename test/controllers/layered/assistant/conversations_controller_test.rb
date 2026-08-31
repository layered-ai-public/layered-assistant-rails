require "test_helper"

module Layered
  module Assistant
    class ConversationsControllerTest < ActionDispatch::IntegrationTest
      test "should get index" do
        get "/layered/assistant/conversations"
        assert_response :success
        assert_select "table.l-ui-table"
        assert_select "th", text: "User"
      end

      test "should get show" do
        conversation = layered_assistant_conversations(:greeting)

        get "/layered/assistant/conversations/#{conversation.uid}"
        assert_response :success
        assert_select ".l-ui-message--sent .l-ui-message__bubble"
        assert_select ".l-ui-message .l-ui-message__author", text: "Assistant"
      end

      test "show renders a tool result and leaves out the message that asked for it" do
        conversation = layered_assistant_conversations(:greeting)
        conversation.messages.create!(
          role: :assistant,
          content: nil,
          tool_calls: [ { "id" => "call_1", "type" => "function", "function" => { "name" => "lookup", "arguments" => '{"term":"rails"}' } } ]
        )
        conversation.messages.create!(
          role: :tool,
          content: '{"found":true}',
          tool_call_id: "call_1",
          tool_name: "lookup",
          tool_arguments: '{"term":"rails"}'
        )

        get "/layered/assistant/conversations/#{conversation.uid}"

        assert_response :success
        assert_select "details.l-ui-surface--collapsible-highlighted .l-ui-surface__summary", text: /Tool:\s+lookup/
        assert_select "details.l-ui-surface--collapsible-highlighted pre code", count: 2
        assert_select ".l-ui-typing-indicator", count: 0
      end

      test "should get new" do
        get "/layered/assistant/conversations/new"
        assert_response :success
        assert_select "form"
      end

      test "should create conversation with valid params" do
        assistant = layered_assistant_assistants(:general)

        assert_difference("Conversation.count", 1) do
          post "/layered/assistant/conversations", params: { conversation: { name: "New", assistant_id: assistant.id } }
        end

        conversation = Conversation.order(:id).last
        assert_equal assistant, conversation.assistant
        assert_equal users(:one), conversation.owner
        assert_redirected_to "/layered/assistant/conversations/#{conversation.uid}"
      end

      test "should reject out-of-scope assistant_id on create" do
        assistant = layered_assistant_assistants(:general)
        assistant.update!(owner: nil)

        assert_no_difference("Conversation.count") do
          post "/layered/assistant/conversations", params: { conversation: { name: "Sneaky", assistant_id: assistant.id } }
        end

        assert_response :not_found
      end

      test "should not create conversation with invalid params" do
        assert_no_difference("Conversation.count") do
          post "/layered/assistant/conversations", params: { conversation: { name: "" } }
        end

        assert_response :unprocessable_entity
        assert_select ".l-ui-form__errors"
      end

      test "should get edit" do
        conversation = layered_assistant_conversations(:greeting)

        get "/layered/assistant/conversations/#{conversation.uid}/edit"
        assert_response :success
        assert_select "input[value=?]", conversation.name
      end

      test "should update conversation with valid params" do
        conversation = layered_assistant_conversations(:greeting)

        patch "/layered/assistant/conversations/#{conversation.uid}", params: { conversation: { name: "Updated Name" } }
        assert_redirected_to "/layered/assistant/conversations"
        assert_equal "Conversation was successfully updated.", flash[:notice]

        conversation.reload
        assert_equal "Updated Name", conversation.name
      end

      test "should not update conversation with invalid params" do
        conversation = layered_assistant_conversations(:greeting)

        patch "/layered/assistant/conversations/#{conversation.uid}", params: { conversation: { name: "" } }
        assert_response :unprocessable_entity
        assert_select ".l-ui-form__errors"
      end

      test "should stop responding assistant message" do
        conversation = layered_assistant_conversations(:greeting)
        assistant_message = conversation.messages.create!(
          uid: "msg_stop_test",
          role: :assistant,
          content: "Partial response",
          model: layered_assistant_models(:sonnet)
        )

        patch "/layered/assistant/conversations/#{conversation.uid}/stop"
        assert_response :ok

        assistant_message.reload
        assert assistant_message.stopped?
      end

      test "stop returns no content when nothing to stop" do
        conversation = layered_assistant_conversations(:coding)

        patch "/layered/assistant/conversations/#{conversation.uid}/stop"
        assert_response :no_content
      end

      test "should destroy conversation" do
        conversation = layered_assistant_conversations(:greeting)

        assert_difference("Conversation.count", -1) do
          delete "/layered/assistant/conversations/#{conversation.uid}"
        end

        assert_redirected_to "/layered/assistant/conversations"
        assert_equal "Conversation was successfully deleted.", flash[:notice]
      end
    end
  end
end
