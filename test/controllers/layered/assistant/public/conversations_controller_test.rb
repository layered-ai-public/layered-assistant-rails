require "test_helper"

module Layered
  module Assistant
    module Public
      class ConversationsControllerTest < ActionDispatch::IntegrationTest
        setup do
          sign_out :user
          @assistant = layered_assistant_assistants(:coding)
        end

        test "create stores conversation in session" do
          assert_difference("Conversation.count", 1) do
            post "/layered/assistant/public/conversations", params: { assistant_id: @assistant.id }
          end

          conversation = Conversation.order(:id).last
          assert_nil conversation.owner
          assert_equal @assistant, conversation.assistant
          assert_response :redirect
        end

        test "should not create conversation for private assistant" do
          private_assistant = layered_assistant_assistants(:private)

          assert_no_difference("Conversation.count") do
            post "/layered/assistant/public/conversations", params: { assistant_id: private_assistant.id }
          end
          assert_response :not_found
        end

        test "show works after create" do
          post "/layered/assistant/public/conversations", params: { assistant_id: @assistant.id }
          conversation = Conversation.order(:id).last

          get "/layered/assistant/public/conversations/#{conversation.id}"
          assert_response :success
          assert_select "h1", text: conversation.name
        end

        test "show redirects to assistants when conversation not in session" do
          conversation = layered_assistant_conversations(:coding)
          get "/layered/assistant/public/conversations/#{conversation.id}"
          assert_redirected_to "/layered/assistant/public/assistants"
        end
      end
    end
  end
end
