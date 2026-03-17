require "test_helper"

module Layered
  module Assistant
    module Public
      module Panel
        class ConversationsControllerTest < ActionDispatch::IntegrationTest
          setup do
            sign_out :user
            @assistant = layered_assistant_assistants(:coding)
          end

          test "index renders for public assistant" do
            get "/layered/assistant/public/panel/conversations", params: { assistant_id: @assistant.id }
            assert_response :success
            assert_select "turbo-frame#assistant_panel_header"
            assert_select "turbo-frame#assistant_panel"
            assert_select "h2", text: @assistant.name
            assert_select "input[type=submit][value='Start conversation']"
          end

          test "index returns 404 for private assistant" do
            private_assistant = layered_assistant_assistants(:private)
            get "/layered/assistant/public/panel/conversations", params: { assistant_id: private_assistant.id }
            assert_response :not_found
          end

          test "lobby renders new conversation form" do
            get "/layered/assistant/public/panel/conversations/new", params: { assistant_id: @assistant.id }
            assert_response :success
            assert_select "turbo-frame#assistant_panel_header"
            assert_select "h2", text: @assistant.name
            assert_select "input[type=submit][value='Start conversation']"
          end

          test "new allows starting fresh conversation even with existing one" do
            post "/layered/assistant/public/panel/conversations", params: { assistant_id: @assistant.id }

            get "/layered/assistant/public/panel/conversations/new", params: { assistant_id: @assistant.id }
            assert_response :success
          end

          test "create stores conversation in session and redirects" do
            assert_difference("Conversation.count", 1) do
              post "/layered/assistant/public/panel/conversations", params: { assistant_id: @assistant.id }
            end

            conversation = Conversation.order(:id).last
            assert_nil conversation.owner
            assert_equal @assistant, conversation.assistant

            assert_response :redirect
            follow_redirect!
            assert_response :success
          end

          test "create returns 404 for private assistant" do
            private_assistant = layered_assistant_assistants(:private)

            assert_no_difference("Conversation.count") do
              post "/layered/assistant/public/panel/conversations", params: { assistant_id: private_assistant.id }
            end
            assert_response :not_found
          end

          test "show works for conversation in session" do
            post "/layered/assistant/public/panel/conversations", params: { assistant_id: @assistant.id }
            conversation = Conversation.order(:id).last

            get "/layered/assistant/public/panel/conversations/#{conversation.uid}"
            assert_response :success
            assert_select "turbo-frame#assistant_panel"
            assert_select ".l-ui-conversation__container"
          end

          test "stop marks assistant message as stopped" do
            post "/layered/assistant/public/panel/conversations", params: { assistant_id: @assistant.id }
            conversation = Conversation.order(:id).last

            assistant_message = conversation.messages.create!(
              uid: "msg_pub_panel_stop",
              role: :assistant,
              content: "Partial",
              model: layered_assistant_models(:sonnet)
            )

            patch "/layered/assistant/public/panel/conversations/#{conversation.uid}/stop"
            assert_response :ok

            assistant_message.reload
            assert assistant_message.stopped?
          end

          test "show redirects to panel lobby when conversation not in session" do
            conversation = layered_assistant_conversations(:coding)
            get "/layered/assistant/public/panel/conversations/#{conversation.uid}"
            assert_redirected_to "/layered/assistant/public/panel/conversations?assistant_id=#{conversation.assistant.id}"
          end
        end
      end
    end
  end
end
