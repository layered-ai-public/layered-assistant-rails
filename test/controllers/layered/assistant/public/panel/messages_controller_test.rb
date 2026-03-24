require "test_helper"

module Layered
  module Assistant
    module Public
      module Panel
        class MessagesControllerTest < ActionDispatch::IntegrationTest
          setup do
            sign_out :user
            @assistant = layered_assistant_assistants(:coding)

            post "/layered/assistant/public/panel/conversations", params: { assistant_id: @assistant.id }
            @conversation = Conversation.order(:id).last
          end

          test "should create message using assistant default model" do
            assert_difference("Message.count", 2) do
              assert_enqueued_with(job: Messages::ResponseJob) do
                post "/layered/assistant/public/panel/conversations/#{@conversation.uid}/messages",
                  params: { message: { content: "Hello from public panel" } },
                  as: :turbo_stream
              end
            end

            user_message = Message.where(role: "user").order(:id).last
            assert_equal "Hello from public panel", user_message.content
            assert_equal @assistant.default_model_id, user_message.model_id

            assistant_message = Message.where(role: "assistant").order(:id).last
            assert_nil assistant_message.content
            assert_equal @assistant.default_model_id, assistant_message.model_id
          end

          test "should respond with turbo_stream" do
            post "/layered/assistant/public/panel/conversations/#{@conversation.uid}/messages",
              params: { message: { content: "Test" } },
              as: :turbo_stream

            assert_response :success
            assert_includes response.content_type, "turbo-stream"
          end

          test "ignores model_id from params and uses assistant default" do
            other_model = layered_assistant_models(:haiku)

            post "/layered/assistant/public/panel/conversations/#{@conversation.uid}/messages",
              params: { message: { content: "Test", model_id: other_model.id } },
              as: :turbo_stream

            user_message = Message.where(role: "user").order(:id).last
            assert_equal @assistant.default_model_id, user_message.model_id
          end

          test "redirects to panel lobby when conversation not in session" do
            conversation = layered_assistant_conversations(:coding)

            assert_no_difference("Message.count") do
              post "/layered/assistant/public/panel/conversations/#{conversation.uid}/messages",
                params: { message: { content: "Hello" } },
                as: :turbo_stream
            end
            assert_redirected_to "/layered/assistant/public/panel/conversations/new?assistant_id=#{conversation.assistant.id}"
          end
        end
      end
    end
  end
end
