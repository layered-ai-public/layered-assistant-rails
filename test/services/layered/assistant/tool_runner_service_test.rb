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

      setup do
        @original_tools = Layered::Assistant.tools_block
        Layered::Assistant.tools { [ EchoTool, BrokenTool ] }

        @conversation = layered_assistant_conversations(:empty)
        @conversation.messages.create!(role: :user, content: "Echo rails")

        # The runner checks the assistant was given the tool before running
        # it, so the fixture assistant behind these conversations gets both.
        layered_assistant_assistants(:general).update!(tool_names: [ "echo", "broken" ])
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

      test "a message with no tool calls does nothing" do
        message = @conversation.messages.create!(role: :assistant, content: "All done", model: layered_assistant_models(:sonnet))

        assert_no_enqueued_jobs(only: Messages::ResponseJob) do
          ToolRunnerService.new.call(message: message)
        end

        assert_empty @conversation.messages.where(role: :tool)
      end

      private

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
