require "test_helper"

module Layered
  module Assistant
    class ToolRegistryTest < ActiveSupport::TestCase
      class OwnedTool < Tool
        description "Needs an owner."
      end

      class OpenTool < Tool
        description "Needs nothing."
        self.public = true
      end

      class PermittedTool < Tool
        description "Only for someone signed in."
        permit { |conversation| conversation.user.present? }
      end

      setup do
        @original_tools = Layered::Assistant.tools_block
        Layered::Assistant.tools { [ OwnedTool, OpenTool ] }

        # `for` offers an assistant only the tools it has been given, so the
        # fixture assistant behind both conversations is given both.
        @assistant = layered_assistant_assistants(:general)
        @assistant.update!(tool_names: [ OwnedTool.tool_name, OpenTool.tool_name ])
      end

      teardown do
        Layered::Assistant.tools(&@original_tools)
        Layered::Assistant.authorize_tool(&nil)
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

      test "for withholds a tool the assistant has not been given" do
        @assistant.update!(tool_names: [ OpenTool.tool_name ])

        assert_equal [ OpenTool ], ToolRegistry.for(layered_assistant_conversations(:greeting))
      end

      test "for offers nothing to an assistant with no tools" do
        @assistant.update!(tool_names: [])

        assert_empty ToolRegistry.for(layered_assistant_conversations(:greeting))
      end

      test "for ignores a name with no registered tool class" do
        @assistant.update!(tool_names: [ OpenTool.tool_name, "since-deleted" ])

        assert_equal [ OpenTool ], ToolRegistry.for(layered_assistant_conversations(:greeting))
      end

      test "for withholds a tool whose permit block refuses the conversation" do
        Layered::Assistant.tools { [ OwnedTool, PermittedTool ] }
        @assistant.update!(tool_names: [ OwnedTool.tool_name, PermittedTool.tool_name ])
        conversation = layered_assistant_conversations(:greeting)
        conversation.update!(user: nil)

        assert_equal [ OwnedTool ], ToolRegistry.for(conversation)

        conversation.update!(user: users(:one))
        assert_equal [ OwnedTool, PermittedTool ], ToolRegistry.for(conversation)
      end

      test "for withholds every tool the authorize_tool block refuses" do
        Layered::Assistant.authorize_tool { |tool, _conversation| tool == OpenTool }

        assert_equal [ OpenTool ], ToolRegistry.for(layered_assistant_conversations(:greeting))
      end

      test "find looks a tool up by the name the model calls it" do
        assert_equal OpenTool, ToolRegistry.find(OpenTool.tool_name)
        assert_nil ToolRegistry.find("no-such-tool")
      end
    end
  end
end
