require "test_helper"

module Layered
  module Assistant
    module Panel
      class ConversationsControllerTest < ActionDispatch::IntegrationTest
        test "should get index" do
          get "/layered/assistant/panel/conversations"
          assert_response :success
          assert_select "turbo-frame#assistant_panel"
          assert_select "table.l-ui-table"
        end

        test "should get show" do
          conversation = layered_assistant_conversations(:greeting)

          get "/layered/assistant/panel/conversations/#{conversation.id}"
          assert_response :success
          assert_select "turbo-frame#assistant_panel"
          assert_select ".l-ui-conversation__container"
        end

        test "should get new" do
          get "/layered/assistant/panel/conversations/new"
          assert_response :success
          assert_select "turbo-frame#assistant_panel"
          assert_select "form.l-ui-form"
        end

        test "should create conversation and redirect to show" do
          assistant = layered_assistant_assistants(:general)

          assert_difference("Conversation.count", 1) do
            post "/layered/assistant/panel/conversations", params: { conversation: { assistant_id: assistant.id } }
          end

          conversation = Conversation.order(:id).last
          assert_equal users(:one), conversation.owner

          assert_response :redirect
          follow_redirect!
          assert_response :success
        end

        test "should stop responding assistant message" do
          conversation = layered_assistant_conversations(:greeting)
          assistant_message = conversation.messages.create!(
            uid: "msg_panel_stop",
            role: :assistant,
            content: "Partial",
            model: layered_assistant_models(:sonnet)
          )

          patch "/layered/assistant/panel/conversations/#{conversation.id}/stop"
          assert_response :ok

          assistant_message.reload
          assert assistant_message.stopped?
        end
      end
    end
  end
end
