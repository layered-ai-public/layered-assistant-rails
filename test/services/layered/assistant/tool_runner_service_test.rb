require "test_helper"

module Layered
  module Assistant
    class ToolRunnerServiceTest < ActiveSupport::TestCase
      include ActiveJob::TestHelper

      class EchoTool < Tool
        tool_name "echo"
        description "Echo a word back."

        argument :word, :string, required: true

        def call(word:)
          { echoed: word }
        end
      end

      class BrokenTool < Tool
        tool_name "broken"
        description "Always fails."

        def call
          raise "the kettle exploded"
        end
      end

      class GuardedTool < Tool
        tool_name "guarded"
        description "Asks first."
        consent :always

        argument :word, :string, required: true

        def call(word:)
          { guarded: word }
        end
      end

      setup do
        @original_tools = Layered::Assistant.tools_block
        Layered::Assistant.tools { [ EchoTool, BrokenTool, GuardedTool ] }

        @conversation = layered_assistant_conversations(:empty)
        @conversation.messages.create!(role: :user, content: "Echo rails")

        # The runner checks the assistant was given the tool before running
        # it, so the fixture assistant behind these conversations gets both.
        layered_assistant_assistants(:general).update!(tool_names: [ "echo", "broken", "guarded" ])
      end

      teardown do
        Layered::Assistant.tools(&@original_tools)
      end

      test "records the result of each call and queues the follow-up response" do
        message = assistant_message_with([ tool_call("call_1", "echo", '{"word":"rails"}') ])

        assert_enqueued_with(job: Messages::ResponseJob) do
          ToolRunnerService.new.call(message: message)
        end

        result = @conversation.messages.where(role: :tool).sole
        assert_equal "call_1", result.tool_call_id
        assert_equal "echo", result.tool_name
        assert_equal '{"word":"rails"}', result.tool_arguments
        assert_equal({ "echoed" => "rails" }, JSON.parse(result.content))
        assert result.input_tokens.positive?
        assert result.tokens_estimated?
      end

      test "records a result per parallel call" do
        message = assistant_message_with([
          tool_call("call_1", "echo", '{"word":"one"}'),
          tool_call("call_2", "echo", '{"word":"two"}')
        ])

        ToolRunnerService.new.call(message: message)

        assert_equal [ "call_1", "call_2" ], @conversation.messages.where(role: :tool).order(:created_at).pluck(:tool_call_id)
      end

      test "the follow-up message is a fresh assistant message on the same model" do
        message = assistant_message_with([ tool_call("call_1", "echo", '{"word":"rails"}') ])

        ToolRunnerService.new.call(message: message)

        follow_up = @conversation.messages.where(role: :assistant).order(:created_at).last
        assert_not_equal message, follow_up
        assert_nil follow_up.content
        assert_equal message.model_id, follow_up.model_id
      end

      test "a tool that raises reports the error back rather than failing the response" do
        message = assistant_message_with([ tool_call("call_1", "broken", "{}") ])

        ToolRunnerService.new.call(message: message)

        result = @conversation.messages.where(role: :tool).sole
        assert_match "the kettle exploded", JSON.parse(result.content)["error"]
      end

      test "an unknown tool is reported back to the model" do
        message = assistant_message_with([ tool_call("call_1", "nonsense", "{}") ])

        ToolRunnerService.new.call(message: message)

        assert_match "no tool called", JSON.parse(@conversation.messages.where(role: :tool).sole.content)["error"]
      end

      test "missing arguments are reported back to the model" do
        message = assistant_message_with([ tool_call("call_1", "echo", "{}") ])

        ToolRunnerService.new.call(message: message)

        assert_match "word", JSON.parse(@conversation.messages.where(role: :tool).sole.content)["error"]
      end

      test "unparseable arguments are reported back to the model" do
        message = assistant_message_with([ tool_call("call_1", "echo", "{not json") ])

        ToolRunnerService.new.call(message: message)

        assert_match "valid JSON", JSON.parse(@conversation.messages.where(role: :tool).sole.content)["error"]
      end

      test "a tool requiring an owner is refused in a conversation without one" do
        @conversation = layered_assistant_conversations(:anonymous)
        message = assistant_message_with([ tool_call("call_1", "echo", '{"word":"rails"}') ])

        ToolRunnerService.new.call(message: message)

        assert_match "not available", JSON.parse(@conversation.messages.where(role: :tool).sole.content)["error"]
      end

      test "a tool the assistant was not given is refused" do
        layered_assistant_assistants(:general).update!(tool_names: [ "broken" ])
        message = assistant_message_with([ tool_call("call_1", "echo", '{"word":"rails"}') ])

        ToolRunnerService.new.call(message: message)

        assert_match "not available", JSON.parse(@conversation.messages.where(role: :tool).sole.content)["error"]
      end

      test "the registrations block is evaluated once however many tools are called" do
        calls = 0
        Layered::Assistant.tools { calls += 1; [ EchoTool, BrokenTool ] }
        message = assistant_message_with([
          tool_call("call_1", "echo", '{"word":"one"}'),
          tool_call("call_2", "echo", '{"word":"two"}')
        ])
        calls = 0

        ToolRunnerService.new.call(message: message)

        assert_equal 1, calls
      end

      test "the loop stops once max_tool_cycles is reached" do
        Layered::Assistant.max_tool_cycles = 2
        2.times { |i| assistant_message_with([ tool_call("spent_#{i}", "echo", '{"word":"x"}') ]) }
        message = @conversation.messages.where(role: :assistant).order(:created_at).last

        assert_no_enqueued_jobs(only: Messages::ResponseJob) do
          ToolRunnerService.new.call(message: message)
        end

        assert_match "rounds of tool calls", @conversation.messages.where(role: :assistant).order(:created_at).last.content
      ensure
        Layered::Assistant.max_tool_cycles = 10
      end

      test "a tool that asks for consent is recorded unanswered and not run" do
        message = assistant_message_with([ tool_call("call_1", "guarded", '{"word":"rails"}') ])

        assert_no_enqueued_jobs(only: Messages::ResponseJob) do
          ToolRunnerService.new.call(message: message)
        end

        result = @conversation.messages.where(role: :tool).sole
        assert result.consent_pending?
        assert_nil result.content
        assert_equal '{"word":"rails"}', result.tool_arguments
        assert @conversation.awaiting_consent?
        assert @conversation.responding?
      end

      # Each call stands on its own: waiting on one is no reason to hold up
      # the reads the model asked for alongside it.
      test "calls needing no consent still run alongside one that does" do
        message = assistant_message_with([
          tool_call("call_1", "echo", '{"word":"rails"}'),
          tool_call("call_2", "guarded", '{"word":"rails"}')
        ])

        ToolRunnerService.new.call(message: message)

        echoed, guarded = @conversation.messages.where(role: :tool).order(:created_at).to_a
        assert_equal({ "echoed" => "rails" }, JSON.parse(echoed.content))
        assert guarded.consent_pending?
      end

      test "approving runs the tool and picks the response back up" do
        pending = pending_call
        pending.update!(tool_status: :approved)

        assert_enqueued_with(job: Messages::ResponseJob) do
          ToolRunnerService.new.resolve(message: pending)
        end

        assert_equal({ "guarded" => "rails" }, JSON.parse(pending.reload.content))
        assert pending.consent_approved?
        assert_not @conversation.awaiting_consent?
      end

      # The model is told it was turned down rather than left hanging: it can
      # say something useful about that.
      test "declining reports the refusal and picks the response back up" do
        pending = pending_call
        pending.update!(tool_status: :declined)

        assert_enqueued_with(job: Messages::ResponseJob) do
          ToolRunnerService.new.resolve(message: pending)
        end

        assert_match "declined", JSON.parse(pending.reload.content)["error"]
        assert pending.consent_declined?
      end

      test "the response waits until every call in the batch has an answer" do
        message = assistant_message_with([
          tool_call("call_1", "guarded", '{"word":"one"}'),
          tool_call("call_2", "guarded", '{"word":"two"}')
        ])
        ToolRunnerService.new.call(message: message)
        first, second = @conversation.messages.where(role: :tool).order(:created_at).to_a

        first.update!(tool_status: :approved)
        assert_no_enqueued_jobs(only: Messages::ResponseJob) do
          ToolRunnerService.new.resolve(message: first)
        end

        second.update!(tool_status: :approved)
        assert_enqueued_with(job: Messages::ResponseJob) do
          ToolRunnerService.new.resolve(message: second)
        end
      end

      # Two approvals landing together must not each decide they were last.
      test "only one follow-up is queued however the last calls resolve" do
        message = assistant_message_with([
          tool_call("call_1", "guarded", '{"word":"one"}'),
          tool_call("call_2", "guarded", '{"word":"two"}')
        ])
        ToolRunnerService.new.call(message: message)
        first, second = @conversation.messages.where(role: :tool).order(:created_at).to_a
        [ first, second ].each { |call| call.update!(tool_status: :approved, content: "done") }

        assert_enqueued_jobs 1, only: Messages::ResponseJob do
          ToolRunnerService.new.resolve(message: first)
          ToolRunnerService.new.resolve(message: second)
        end
      end

      test "a message with no tool calls does nothing" do
        message = @conversation.messages.create!(role: :assistant, content: "All done", model: layered_assistant_models(:sonnet))

        assert_no_enqueued_jobs(only: Messages::ResponseJob) do
          ToolRunnerService.new.call(message: message)
        end

        assert_empty @conversation.messages.where(role: :tool)
      end

      private

      def pending_call
        message = assistant_message_with([ tool_call("call_1", "guarded", '{"word":"rails"}') ])
        ToolRunnerService.new.call(message: message)
        @conversation.messages.where(role: :tool).sole
      end

      def assistant_message_with(tool_calls)
        @conversation.messages.create!(
          role: :assistant,
          content: nil,
          model: layered_assistant_models(:sonnet),
          tool_calls: tool_calls
        )
      end

      def tool_call(id, name, arguments)
        { "id" => id, "type" => "function", "function" => { "name" => name, "arguments" => arguments } }
      end
    end
  end
end
