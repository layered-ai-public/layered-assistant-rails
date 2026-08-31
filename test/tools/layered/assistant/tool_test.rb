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

      class PublicTool < Tool
        self.public = true
      end

      class BaseLookupTool < Tool
        description "Look something up."
        self.public = true

        argument :query, :string, required: true, description: "What to look for."
        argument :limit, :integer
      end

      class NarrowedLookupTool < BaseLookupTool
        argument :limit, :integer, required: true, description: "How many to return."
        argument :sort, :string
      end

      test "a subclass inherits the declarations it does not make itself" do
        assert_equal "Look something up.", NarrowedLookupTool.description
        assert NarrowedLookupTool.public?
      end

      test "a subclass takes its own name rather than its parent's" do
        assert_equal "layered-assistant-tool_test-base_lookup", BaseLookupTool.tool_name
        assert_equal "layered-assistant-tool_test-narrowed_lookup", NarrowedLookupTool.tool_name
      end

      test "a subclass adds to the arguments it inherits" do
        assert_equal [ :query, :limit, :sort ], NarrowedLookupTool.arguments.map { |argument| argument[:name] }
        assert_equal [ :query, :limit ], BaseLookupTool.arguments.map { |argument| argument[:name] }
      end

      test "a redeclared argument overrides where it already sits" do
        limit = NarrowedLookupTool.arguments.find { |argument| argument[:name] == :limit }

        assert_equal "How many to return.", limit[:description]
        assert_equal [ "query", "limit" ], NarrowedLookupTool.schema[:required]
      end

      # `inherited` is Ruby's hook for being subclassed. The reader that walks
      # up to the parent must not be called that, or defining any tool breaks.
      test "subclassing a tool does not blow up" do
        assert_nothing_raised { Class.new(BaseLookupTool) }
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

      test "tools are private by default" do
        assert_not GreetTool.public?
        assert_not GreetTool.available_for?(nil)
        assert_not GreetTool.available_for?(layered_assistant_conversations(:anonymous))
        assert GreetTool.available_for?(layered_assistant_conversations(:greeting))
      end

      test "a public tool is offered to conversations without an owner" do
        assert PublicTool.public?
        assert PublicTool.available_for?(layered_assistant_conversations(:anonymous))
      end

      test "public does not leak to a sibling tool" do
        assert PublicTool.public?
        assert_not GreetTool.public?
      end

      # `public` is Ruby's visibility keyword, so the flag is an attribute
      # rather than a DSL method - reopening visibility in a tool body must
      # not quietly expose it to anonymous visitors.
      test "a bare public in a tool body does not mark the tool public" do
        tool = Class.new(Tool) do
          private def helper = nil
          public def call = "hi"
        end

        assert_not tool.public?
      end

      test "call must be implemented" do
        assert_raises(NotImplementedError) { PublicTool.new.call }
      end

      test "a tool reads the conversation, owner and user from its message" do
        message = layered_assistant_messages(:greeting_reply)
        message.conversation.update!(user: users(:one))
        tool = GreetTool.new(message: message)

        assert_equal message.conversation, tool.conversation
        assert_equal message.conversation.owner, tool.owner
        assert_equal users(:one), tool.user
      end

      # Stands in for an owner block scoping records to an organisation: the
      # boundary is one record, the person who asked is another.
      test "owner and user differ once ownership is scoped elsewhere" do
        message = layered_assistant_messages(:greeting_reply)
        message.conversation.update!(owner: users(:other), user: users(:one))
        tool = GreetTool.new(message: message)

        assert_equal users(:other), tool.owner
        assert_equal users(:one), tool.user
      end

      test "user is nil for an anonymous visitor" do
        message = layered_assistant_messages(:greeting_reply)
        message.conversation.update!(owner: nil, user: nil)

        assert_nil GreetTool.new(message: message).user
      end
    end
  end
end
