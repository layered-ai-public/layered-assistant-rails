require "test_helper"

module Layered
  module Assistant
    class ToolRegistryTest < ActiveSupport::TestCase
      class OwnedTool < Tool
        description "Needs an owner."
      end

      class OpenTool < Tool
        description "Needs nothing."
        requires_owner false
      end

      setup do
        @original_tools = Layered::Assistant.tools_block
        Layered::Assistant.tools { [ OwnedTool, OpenTool ] }
      end

      teardown do
        Layered::Assistant.tools(&@original_tools)
      end

      test "all returns the configured tools" do
        assert_equal [ OwnedTool, OpenTool ], ToolRegistry.all
      end

      test "all resolves class names given as strings" do
        Layered::Assistant.tools { [ "Layered::Assistant::ToolRegistryTest::OpenTool" ] }

        assert_equal [ OpenTool ], ToolRegistry.all
      end

      test "all is empty when no tools are configured" do
        Layered::Assistant.tools(&nil)

        assert_empty ToolRegistry.all
      end

      test "for withholds owner-requiring tools from a conversation without an owner" do
        assert_equal [ OpenTool ], ToolRegistry.for(layered_assistant_conversations(:anonymous))
      end

      test "for offers every tool to an owned conversation" do
        assert_equal [ OwnedTool, OpenTool ], ToolRegistry.for(layered_assistant_conversations(:greeting))
      end

      test "find looks a tool up by the name the model calls it" do
        assert_equal OpenTool, ToolRegistry.find(OpenTool.tool_name)
        assert_nil ToolRegistry.find("no-such-tool")
      end
    end
  end
end
