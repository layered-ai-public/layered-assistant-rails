require "test_helper"

module Layered
  module Assistant
    module Panel
      class MessagesControllerTest < ActionDispatch::IntegrationTest
        setup do
          @conversation = layered_assistant_conversations(:greeting)
          @model = layered_assistant_models(:sonnet)
        end

        test "should create message and enqueue ai response job" do
          assert_difference("Message.count", 2) do
            assert_enqueued_with(job: Messages::ResponseJob) do
              post "/layered/assistant/panel/conversations/#{@conversation.id}/messages",
                params: { message: { content: "Hello from panel", model_id: @model.id } },
                as: :turbo_stream
            end
          end

          user_message = Message.where(role: "user").order(:id).last
          assert_equal "Hello from panel", user_message.content
          assert_equal @model.id, user_message.model_id

          assistant_message = Message.where(role: "assistant").order(:id).last
          assert_nil assistant_message.content
          assert_equal @model.id, assistant_message.model_id
        end

        test "should respond with turbo_stream" do
          post "/layered/assistant/panel/conversations/#{@conversation.id}/messages",
            params: { message: { content: "Test", model_id: @model.id } },
            as: :turbo_stream

          assert_response :success
          assert_includes response.content_type, "turbo-stream"
        end
      end
    end
  end
end
