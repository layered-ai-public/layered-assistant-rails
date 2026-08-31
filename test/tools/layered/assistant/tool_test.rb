require "test_helper"

module Layered
  module Assistant
    class ToolTest < ActiveSupport::TestCase
      class GreetTool < Tool
        description "Greet someone."

        argument :name, :string, required: true, description: "Who to greet."
        argument :times, :integer, description: "How many times."
        argument :tags, :array, items: :string

        def call(name:, times: 1, tags: [])
          "Hello #{name}" * times
        end
      end

      class Weather
        class ForecastTool < Tool
        end
      end

      class NamedTool < Tool
        tool_name "custom-name"
      end

      class AnonymousTool < Tool
        requires_owner false
      end

      test "tool name derives from the class name, hyphenating namespaces" do
        assert_equal "layered-assistant-tool_test-weather-forecast", Weather::ForecastTool.tool_name
      end

      test "tool name can be set explicitly" do
        assert_equal "custom-name", NamedTool.tool_name
      end

      test "schema describes the arguments" do
        schema = GreetTool.schema

        assert_equal "object", schema[:type]
        assert_equal [ "name" ], schema[:required]
        assert_equal({ type: "string", description: "Who to greet." }, schema[:properties]["name"])
        assert_equal({ type: "integer", description: "How many times." }, schema[:properties]["times"])
        assert_equal({ type: "array", items: { type: "string" } }, schema[:properties]["tags"])
        assert_equal false, schema[:additionalProperties]
      end

      test "cast_arguments symbolizes and drops unknown keys" do
        assert_equal({ name: "Ada" }, GreetTool.cast_arguments({ "name" => "Ada", "colour" => "red" }))
      end

      test "cast_arguments raises when a required argument is missing" do
        error = assert_raises(Tool::InvalidArguments) { GreetTool.cast_arguments({}) }
        assert_match "name", error.message
      end

      test "argument rejects an unsupported type" do
        assert_raises(::ArgumentError) do
          Class.new(Tool) { argument :thing, :widget }
        end
      end

      test "tools require an owner by default" do
        assert_not GreetTool.available_for?(nil)
        assert_not GreetTool.available_for?(layered_assistant_conversations(:anonymous))
        assert GreetTool.available_for?(layered_assistant_conversations(:greeting))
      end

      test "a tool can opt in to conversations without an owner" do
        assert AnonymousTool.available_for?(layered_assistant_conversations(:anonymous))
      end

      test "call must be implemented" do
        assert_raises(NotImplementedError) { AnonymousTool.new.call }
      end

      test "a tool reads the conversation and owner from its message" do
        message = layered_assistant_messages(:greeting_reply)
        tool = GreetTool.new(message: message)

        assert_equal message.conversation, tool.conversation
        assert_equal message.conversation.owner, tool.owner
      end
    end
  end
end
