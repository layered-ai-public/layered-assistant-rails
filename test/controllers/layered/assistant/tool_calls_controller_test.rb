require "test_helper"

module Layered
  module Assistant
    class ToolCallsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @conversation = layered_assistant_conversations(:greeting)
        @message = pending_call(@conversation)
      end

      test "approving records the decision and queues the call" do
        assert_enqueued_with(job: Messages::ToolCallJob) do
          patch tool_call_path(@conversation, @message), params: { decision: "approve" }
        end

        assert_response :no_content
        assert @message.reload.consent_approved?
      end

      test "declining records the decision and queues the refusal" do
        assert_enqueued_with(job: Messages::ToolCallJob) do
          patch tool_call_path(@conversation, @message), params: { decision: "decline" }
        end

        assert_response :no_content
        assert @message.reload.consent_declined?
      end

      # A second click, or a tab left open on a call somebody else has
      # already answered, must not run the tool twice.
      test "deciding twice changes nothing the second time" do
        patch tool_call_path(@conversation, @message), params: { decision: "approve" }

        assert_no_enqueued_jobs(only: Messages::ToolCallJob) do
          patch tool_call_path(@conversation, @message), params: { decision: "decline" }
        end

        assert_response :no_content
        assert @message.reload.consent_approved?
      end

      test "an unknown decision is rejected" do
        patch tool_call_path(@conversation, @message), params: { decision: "maybe" }

        assert_response :unprocessable_entity
        assert @message.reload.consent_pending?
      end

      test "a conversation outside the caller's scope is not found" do
        @conversation.update!(owner: users(:other))

        patch tool_call_path(@conversation, @message), params: { decision: "approve" }

        assert_response :not_found
        assert @message.reload.consent_pending?
      end

      test "a message from another conversation is not found" do
        other = layered_assistant_conversations(:coding)

        patch tool_call_path(other, @message), params: { decision: "approve" }

        assert_response :not_found
      end

      private

      def tool_call_path(conversation, message)
        "/layered/assistant/conversations/#{conversation.uid}/tool_calls/#{message.id}"
      end

      def pending_call(conversation)
        conversation.messages.create!(
          role: :tool,
          content: nil,
          tool_call_id: "call_1",
          tool_name: "guarded",
          tool_arguments: '{"word":"rails"}',
          tool_status: :pending
        )
      end
    end
  end
end
