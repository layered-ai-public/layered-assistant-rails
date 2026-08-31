require "test_helper"

module Layered
  module Assistant
    class ToolDefinitionsServiceTest < ActiveSupport::TestCase
      class LookupTool < Tool
        tool_name "lookup"
        description "Look something up."

        argument :term, :string, required: true
      end

      test "anthropic definitions carry the schema as input_schema" do
        definition = ToolDefinitionsService.new.format([ LookupTool ], provider: layered_assistant_providers(:anthropic)).first

        assert_equal "lookup", definition[:name]
        assert_equal "Look something up.", definition[:description]
        assert_equal LookupTool.schema, definition[:input_schema]
      end

      test "openai definitions wrap the schema in a function" do
        definition = ToolDefinitionsService.new.format([ LookupTool ], provider: layered_assistant_providers(:openai)).first

        assert_equal "function", definition[:type]
        assert_equal "lookup", definition[:function][:name]
        assert_equal LookupTool.schema, definition[:function][:parameters]
      end

      test "anthropic is the default protocol" do
        definition = ToolDefinitionsService.new.format([ LookupTool ]).first

        assert_equal "lookup", definition[:name]
      end

      test "no tools produces no definitions" do
        assert_empty ToolDefinitionsService.new.format([], provider: layered_assistant_providers(:openai))
      end
    end
  end
end
