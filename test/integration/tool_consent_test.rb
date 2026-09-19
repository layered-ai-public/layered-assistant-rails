require "test_helper"

module Layered
  module Assistant
    # The buttons that put a tool call to the person talking. The partial
    # carrying them is broadcast as well as requested, so it has to render
    # without a request around it too.
    class ToolConsentTest < ActionDispatch::IntegrationTest
      setup do
        @conversation = layered_assistant_conversations(:greeting)
        @message = @conversation.messages.create!(
          role: :tool,
          content: nil,
          tool_call_id: "call_1",
          tool_name: "guarded",
          tool_arguments: '{"word":"rails"}',
          tool_status: :pending
        )
      end

      test "a waiting call is shown with its arguments and a decision to make" do
        get "/layered/assistant/panel/conversations/#{@conversation.uid}"

        assert_response :success
        assert_select "details[open]" do
          assert_select "code", text: /rails/
        end
        assert_select "form[action=?][method=?]",
          "/layered/assistant/conversations/#{@conversation.uid}/tool_calls/#{@message.id}", "post", count: 2
        assert_select "button[aria-label=?]", "Approve the call to guarded"
        assert_select "button[aria-label=?]", "Decline the call to guarded"
      end

      test "the composer is disabled while a call waits" do
        get "/layered/assistant/panel/conversations/#{@conversation.uid}"

        assert_select "form[data-composer-responding-value=?]", "true"
      end

      test "an answered call shows its result rather than the buttons" do
        @message.resolve_tool_call!(status: :declined, content: '{"error":"declined"}')

        get "/layered/assistant/panel/conversations/#{@conversation.uid}"

        assert_select "form[action*=?]", "tool_calls", count: 0
        assert_select ".l-ui-notice--warning", text: /declined/i
      end

      # Broadcasts render the partial with no request to build URLs from.
      test "a waiting call broadcasts without a request" do
        assert_nothing_raised { @message.broadcast_updated }
      end
    end
  end
end
