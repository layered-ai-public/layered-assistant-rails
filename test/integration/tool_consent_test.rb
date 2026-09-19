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

      # The composer is disabled while a call waits, so a message arriving
      # anyway is a stale tab. Answering it would send the model a call with
      # no result yet, which the provider rejects.
      test "a message posted while a call waits is refused, and said so" do
        assert_no_difference -> { @conversation.messages.count } do
          post "/layered/assistant/panel/conversations/#{@conversation.uid}/messages",
            params: { message: { content: "Are you there?" } },
            as: :turbo_stream
        end

        assert_response :success
        assert_match "waiting on you", response.body
        assert_match 'data-composer-responding-value="true"', response.body
      end

      # An approved call is still unanswered while the tool runs, and sending
      # then would leave the same gap in what the model is shown.
      test "a message posted while an approved call runs is refused" do
        @message.update!(tool_status: :approved)

        assert_no_difference -> { @conversation.messages.count } do
          post "/layered/assistant/panel/conversations/#{@conversation.uid}/messages",
            params: { message: { content: "Are you there?" } },
            as: :turbo_stream
        end

        assert_match "waiting on you", response.body
      end

      # The buttons go the moment the call is approved, but the tool has yet
      # to run - an empty Output block would read as a tool that returned
      # nothing rather than one still working.
      test "an approved call says it is running rather than showing no output" do
        @message.update!(tool_status: :approved)

        get "/layered/assistant/panel/conversations/#{@conversation.uid}"

        assert_select "form[action*=?]", "tool_calls", count: 0
        assert_select ".l-ui-notice", text: /running/i
        assert_select "p", text: "Output:", count: 0
      end

      # The decision is recorded before the job writes what came of it, and in
      # between the call still holds nothing the model can be shown.
      test "a declined call is unresolved until its refusal is written" do
        @message.update!(tool_status: :declined)

        assert @conversation.unresolved_tool_call?

        assert_no_difference -> { @conversation.messages.count } do
          post "/layered/assistant/panel/conversations/#{@conversation.uid}/messages",
            params: { message: { content: "Are you there?" } },
            as: :turbo_stream
        end

        assert_match "waiting on you", response.body
      end

      # Broadcasts render the partial with no request to build URLs from.
      test "a waiting call broadcasts without a request" do
        assert_nothing_raised { @message.broadcast_updated }
      end
    end
  end
end
