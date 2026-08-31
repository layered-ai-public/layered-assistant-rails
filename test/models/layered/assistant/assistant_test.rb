require "test_helper"

module Layered
  module Assistant
    class AssistantTest < ActiveSupport::TestCase
      test "validates name presence" do
        assistant = Assistant.new(name: nil)
        assert_not assistant.valid?
        assert_includes assistant.errors[:name], "can't be blank"
      end

      test "allows optional fields to be blank" do
        assistant = Assistant.new(name: "Test")
        assert assistant.valid?
        assert_nil assistant.description
        assert_nil assistant.instructions
        assert_nil assistant.default_model_id
      end

      test "belongs to default_model optionally when private" do
        assistant = Assistant.new(name: "Test")
        assert assistant.valid?
        assert_nil assistant.default_model
      end

      test "public assistant has default_model" do
        general = layered_assistant_assistants(:general)
        assert_equal layered_assistant_models(:sonnet), general.default_model

        coding = layered_assistant_assistants(:coding)
        assert_equal layered_assistant_models(:sonnet), coding.default_model
      end

      test "validates default_model presence when public" do
        assistant = Assistant.new(name: "Public test", public: true)
        assert_not assistant.valid?
        assert_includes assistant.errors[:default_model], "can't be blank"

        assistant.default_model = layered_assistant_models(:sonnet)
        assert assistant.valid?
      end

      test "has many conversations" do
        assistant = layered_assistant_assistants(:general)
        assert_includes assistant.conversations, layered_assistant_conversations(:greeting)
      end

      test "destroying assistant destroys conversations" do
        assistant = layered_assistant_assistants(:general)
        conversation_ids = assistant.conversation_ids

        assert conversation_ids.any?
        assistant.destroy
        assert_empty Conversation.where(id: conversation_ids)
      end

      test "by_name scope orders alphabetically" do
        assistants = Assistant.by_name
        assert_equal assistants.map(&:name), assistants.map(&:name).sort
      end

      test "by_created_at scope orders newest first" do
        assistants = Assistant.by_created_at
        assert_equal assistants.map(&:created_at), assistants.map(&:created_at).sort.reverse
      end

      test "defaults to private" do
        assistant = Assistant.new(name: "Test")
        assert_equal false, assistant.public
      end

      test "tool_names lists the tools the assistant has been given" do
        assert_equal [ "current_time" ], layered_assistant_assistants(:coding).tool_names
      end

      test "tool_names is empty for an assistant given none" do
        assert_empty layered_assistant_assistants(:general).tool_names
      end

      test "tool_names= adds and removes to match what it is given" do
        assistant = layered_assistant_assistants(:coding)

        assistant.update!(tool_names: [ "current_time", "user_lookup" ])
        assert_equal [ "current_time", "user_lookup" ], assistant.reload.tool_names

        assistant.update!(tool_names: [ "user_lookup" ])
        assert_equal [ "user_lookup" ], assistant.reload.tool_names
      end

      test "tool_names= ignores blanks and duplicates" do
        assistant = layered_assistant_assistants(:general)

        assistant.update!(tool_names: [ "", "current_time", "current_time" ])

        assert_equal [ "current_time" ], assistant.reload.tool_names
      end

      test "tool_names= keeps the counter cache in step" do
        assistant = layered_assistant_assistants(:general)

        assistant.update!(tool_names: [ "current_time", "user_lookup" ])
        assert_equal 2, assistant.reload.assistant_tools_count

        assistant.update!(tool_names: [])
        assert_equal 0, assistant.reload.assistant_tools_count
      end

      # A name dropped and re-added before the save used to keep the
      # destruction mark it was given on the way out, so it was deleted
      # anyway and took the counter cache to -1.
      test "tool_names= re-assigned before saving keeps the name" do
        assistant = layered_assistant_assistants(:coding)
        assert_equal [ "current_time" ], assistant.tool_names

        assistant.tool_names = []
        assistant.tool_names = [ "current_time" ]
        assistant.save!

        assert_equal [ "current_time" ], assistant.reload.tool_names
        assert_equal 1, assistant.assistant_tools_count
      end

      test "tool_names= keeps the row backing a name that survives" do
        assistant = layered_assistant_assistants(:coding)
        kept = assistant.assistant_tools.sole

        assistant.update!(tool_names: [ "current_time", "user_lookup" ])

        assert_includes assistant.reload.assistant_tools.ids, kept.id
      end

      test "destroying an assistant destroys its tools" do
        assistant = layered_assistant_assistants(:coding)
        tool_ids = assistant.assistant_tools.ids
        assert tool_ids.any?

        assistant.destroy

        assert_empty AssistantTool.where(id: tool_ids)
      end

      test "publicly_available scope returns only public assistants" do
        public_assistants = Assistant.publicly_available
        assert public_assistants.all?(&:public)
        assert_includes public_assistants, layered_assistant_assistants(:coding)
        assert_includes public_assistants, layered_assistant_assistants(:general)
        assert_not_includes public_assistants, layered_assistant_assistants(:private)
      end
    end
  end
end
