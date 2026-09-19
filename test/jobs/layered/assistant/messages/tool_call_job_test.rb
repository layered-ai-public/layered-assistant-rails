require "test_helper"

module Layered
  module Assistant
    module Messages
      class ToolCallJobTest < ActiveSupport::TestCase
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
          Layered::Assistant.tools { [ GuardedTool ] }
          layered_assistant_assistants(:general).update!(tool_names: [ "guarded" ])

          @conversation = layered_assistant_conversations(:empty)
          @message = @conversation.messages.create!(
            role: :tool,
            content: nil,
            tool_call_id: "call_1",
            tool_name: "guarded",
            tool_arguments: '{"word":"rails"}',
            tool_status: :pending
          )
        end

        teardown do
          Layered::Assistant.tools(&@original_tools)
        end

        test "runs an approved call" do
          @message.update!(tool_status: :approved)

          ToolCallJob.perform_now(@message.id)

          assert_equal({ "guarded" => "rails" }, JSON.parse(@message.reload.content))
        end

        test "writes the refusal for a declined call" do
          @message.update!(tool_status: :declined)

          ToolCallJob.perform_now(@message.id)

          assert_match "declined", JSON.parse(@message.reload.content)["error"]
        end

        test "leaves a call still waiting alone" do
          ToolCallJob.perform_now(@message.id)

          assert_nil @message.reload.content
          assert @message.consent_pending?
        end

        # The job can be delivered twice; the tool must not run twice with it.
        test "a call already answered is not run again" do
          @message.update!(tool_status: :approved)
          ToolCallJob.perform_now(@message.id)
          answered = @message.reload.updated_at

          ToolCallJob.perform_now(@message.id)

          assert_equal answered, @message.reload.updated_at
        end
      end
    end
  end
end
