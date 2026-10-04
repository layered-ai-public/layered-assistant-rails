require "test_helper"

module Layered
  module Assistant
    class MessagesControllerTest < ActionDispatch::IntegrationTest
      setup do
        @conversation = layered_assistant_conversations(:greeting)
        @model = layered_assistant_models(:sonnet)
      end

      test "should get index" do
        get "/layered/assistant/conversations/#{@conversation.uid}/messages"
        assert_response :success
        assert_select "table.l-ui-table"
        assert_select ".l-ui-breadcrumbs a[href=?]", "/layered/assistant/conversations/#{@conversation.uid}", text: @conversation.name
      end

      test "should not list another owner's conversation's messages" do
        @conversation.update!(owner: nil)

        get "/layered/assistant/conversations/#{@conversation.uid}/messages"

        assert_response :not_found
      end

      test "should create message and enqueue ai response job" do
        assert_difference("Message.count", 2) do
          assert_enqueued_with(job: Messages::ResponseJob) do
            post "/layered/assistant/conversations/#{@conversation.uid}/messages",
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

      test "should not create a message through another owner's model" do
        @model.provider.update!(owner: nil)

        assert_no_difference("Message.count") do
          post "/layered/assistant/conversations/#{@conversation.uid}/messages",
            params: { message: { content: "Hello", model_id: @model.id } },
            as: :turbo_stream
        end

        assert_response :not_found
      end

      test "should destroy message" do
        message = layered_assistant_messages(:hello)
        message.update!(input_tokens: 10)
        @conversation.update_token_totals!

        assert_difference("Message.count", -1) do
          delete "/layered/assistant/conversations/#{@conversation.uid}/messages/#{message.id}"
        end

        assert_redirected_to "/layered/assistant/conversations/#{@conversation.uid}/messages"
        assert_equal "Message deleted", flash[:notice]
        assert_equal 0, @conversation.reload.input_tokens
      end

      test "should not destroy a message in another owner's conversation" do
        message = layered_assistant_messages(:hello)
        @conversation.update!(owner: nil)

        assert_no_difference("Message.count") do
          delete "/layered/assistant/conversations/#{@conversation.uid}/messages/#{message.id}"
        end

        assert_response :not_found
      end
    end
  end
end
