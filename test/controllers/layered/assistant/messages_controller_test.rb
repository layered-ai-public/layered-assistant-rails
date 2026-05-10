require "test_helper"

module Layered
  module Assistant
    class MessagesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @conversation = layered_assistant_conversations(:greeting)
        @model = layered_assistant_models(:sonnet)
      end

      test "should get index" do
        get "/layered/assistant/conversations/#{@conversation.id}/messages"
        assert_response :success
        assert_select "table.l-ui-table"
      end

      test "should create message and enqueue ai response job" do
        assert_difference("Message.count", 2) do
          assert_enqueued_with(job: Messages::ResponseJob) do
            post "/layered/assistant/conversations/#{@conversation.id}/messages",
              params: { message: { content: "Hello", model_id: @model.id } },
              as: :turbo_stream
          end
        end

        user_message = Message.where(role: "user").order(:id).last
        assert_equal "Hello", user_message.content
        assert_equal @model.id, user_message.model_id

        assistant_message = Message.where(role: "assistant").order(:id).last
        assert_nil assistant_message.content
        assert_equal @model.id, assistant_message.model_id
      end

      test "should destroy message" do
        message = layered_assistant_messages(:hello)

        assert_difference("Message.count", -1) do
          delete "/layered/assistant/conversations/#{@conversation.id}/messages/#{message.id}"
        end

        assert_redirected_to "/layered/assistant/conversations/#{@conversation.id}/messages"
        assert_equal "Message was successfully deleted.", flash[:notice]
      end
    end
  end
end
