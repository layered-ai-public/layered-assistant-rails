require "test_helper"

module Layered
  module Assistant
    module Messages
      class ResponseJobTest < ActiveSupport::TestCase
        include ActiveJob::TestHelper

        class EchoTool < Tool
          tool_name "echo"
          description "Echo a word back."

          argument :word, :string, required: true

          def call(word:)
            { echoed: word }
          end
        end

        # Replays a canned stream in place of a real provider call.
        class FakeClientService
          def initialize(chunks)
            @chunks = chunks
          end

          def call(message:, stream_proc:)
            @chunks.each { |chunk| stream_proc.call(chunk, chunk.to_s.bytesize) }
          end
        end

        setup do
          @original_tools = Layered::Assistant.tools_block
          Layered::Assistant.tools { [ EchoTool ] }

          @conversation = layered_assistant_conversations(:empty)
          # Tools are given per assistant, so registering the tool is not
          # enough on its own - the fixture assistant has to be given it too.
          @conversation.assistant.update!(tool_names: [ EchoTool.tool_name ])
          @conversation.messages.create!(role: :user, content: "Echo rails")
          @message = @conversation.messages.create!(role: :assistant, content: nil, model: layered_assistant_models(:sonnet))
        end

        teardown do
          Layered::Assistant.tools(&@original_tools)
        end

        test "a response that asks for a tool runs it and queues the next response" do
          assert_enqueued_with(job: ResponseJob) do
            perform_with(tool_call_stream)
          end

          assert_equal "echo", @message.reload.tool_calls.first.dig("function", "name")

          result = @conversation.messages.where(role: :tool).sole
          assert_equal({ "echoed" => "rails" }, JSON.parse(result.content))

          follow_up = @conversation.messages.where(role: :assistant).order(:created_at).last
          assert_not_equal @message, follow_up
          assert_nil follow_up.content
        end

        test "a response that answers outright neither runs tools nor queues another" do
          assert_no_enqueued_jobs(only: ResponseJob) do
            perform_with(text_stream)
          end

          assert_equal "All done", @message.reload.content
          assert_empty @conversation.messages.where(role: :tool)
        end

        private

        # Stand FakeClientService in for the real one for the duration of the job.
        def perform_with(chunks)
          fake = FakeClientService.new(chunks)
          ClientService.define_singleton_method(:new) { |*| fake }
          ResponseJob.perform_now(@message.id)
        ensure
          ClientService.singleton_class.remove_method(:new)
        end

        def tool_call_stream
          [
            { "type" => "content_block_start", "index" => 0, "content_block" => { "type" => "tool_use", "id" => "toolu_1", "name" => "echo" } },
            { "type" => "content_block_delta", "index" => 0, "delta" => { "type" => "input_json_delta", "partial_json" => '{"word":"rails"}' } },
            { "type" => "message_stop" }
          ]
        end

        def text_stream
          [
            { "type" => "content_block_delta", "delta" => { "text" => "All done" } },
            { "type" => "message_stop" }
          ]
        end
      end
    end
  end
end
