require "test_helper"

module Layered
  module Assistant
    module Messages
      class ResponseServiceTest < ActiveSupport::TestCase
        setup do
          @conversation = layered_assistant_conversations(:greeting)
          @model = layered_assistant_models(:sonnet)
          @original_tools_block = Layered::Assistant.tools_block
          @original_execute_tool_block = Layered::Assistant.execute_tool_block
        end

        teardown do
          Layered::Assistant.class_variable_set(:@@tools_block, @original_tools_block)
          Layered::Assistant.class_variable_set(:@@execute_tool_block, @original_execute_tool_block)
        end

        # --- No provider ---

        test "sets error content when no provider is configured" do
          message = @conversation.messages.create!(role: :assistant, model: nil)

          ResponseService.new(message).call

          message.reload
          assert_equal "No provider is configured for this model.", message.content
        end

        # --- Simple streaming (no tool calls) ---

        test "streams a simple response with no tool calls" do
          message = @conversation.messages.create!(role: :assistant, model: @model)

          client = fake_client do |stream_proc:|
            stream_proc.call({ "type" => "content_block_delta", "delta" => { "text" => "Hello!" } }, 0)
            stream_proc.call({ "type" => "message_stop" }, 0)
          end

          ResponseService.new(message, client_service: client).call

          assert_equal "Hello!", message.reload.content
        end

        # --- Tool call loop ---

        test "executes tool calls and loops for follow-up response" do
          message = @conversation.messages.create!(role: :assistant, model: @model)
          call_count = 0

          client = fake_client do |stream_proc:|
            call_count += 1

            if call_count == 1
              stream_proc.call({
                "type" => "content_block_start",
                "content_block" => { "type" => "tool_use", "id" => "tool_1", "name" => "lookup" }
              }, 0)
              stream_proc.call({
                "type" => "content_block_delta",
                "delta" => { "type" => "input_json_delta", "partial_json" => '{"query":"test"}' }
              }, 0)
              stream_proc.call({ "type" => "content_block_stop" }, 0)
              stream_proc.call({ "type" => "message_stop" }, 0)
            else
              stream_proc.call({ "type" => "content_block_delta", "delta" => { "text" => "Done" } }, 0)
              stream_proc.call({ "type" => "message_stop" }, 0)
            end
          end

          configure_tools(
            tools: ->(assistant) { [{ name: "lookup" }] },
            execute: ->(name, input, ctx) { "result for #{name}" }
          )

          ResponseService.new(message, client_service: client).call

          assert_equal 2, call_count

          message.reload
          tool_calls = JSON.parse(message.tool_calls)
          assert_equal "lookup", tool_calls.first["name"]

          tool_message = @conversation.messages.where(role: :tool).last
          assert_equal "result for lookup", tool_message.content
          assert_equal "tool_1", tool_message.tool_call_id

          follow_up = @conversation.messages.where(role: :assistant).order(:created_at).last
          assert_equal "Done", follow_up.content
        end

        # --- Max iterations guard ---

        test "stops after MAX_TOOL_ITERATIONS and appends limit message" do
          message = @conversation.messages.create!(role: :assistant, model: @model)

          client = fake_client do |stream_proc:|
            stream_proc.call({
              "type" => "content_block_start",
              "content_block" => { "type" => "tool_use", "id" => "tool_loop", "name" => "repeat" }
            }, 0)
            stream_proc.call({
              "type" => "content_block_delta",
              "delta" => { "type" => "input_json_delta", "partial_json" => "{}" }
            }, 0)
            stream_proc.call({ "type" => "content_block_stop" }, 0)
            stream_proc.call({ "type" => "message_stop" }, 0)
          end

          configure_tools(
            tools: ->(assistant) { [{ name: "repeat" }] },
            execute: ->(_n, _i, _c) { "ok" }
          )

          ResponseService.new(message, client_service: client).call

          last_assistant = @conversation.messages.where(role: :assistant).order(:created_at).last
          assert_includes last_assistant.content, "Tool use limit reached."
        end

        # --- Error handling ---

        test "catches errors and sets error content on the message" do
          message = @conversation.messages.create!(role: :assistant, model: @model)

          client = fake_client do |stream_proc:|
            raise StandardError, "API timeout"
          end

          ResponseService.new(message, client_service: client).call

          message.reload
          assert_equal "Something went wrong while generating a response.", message.content
        end

        test "appends error note to existing partial content" do
          message = @conversation.messages.create!(role: :assistant, model: @model, content: "Partial reply")

          client = fake_client do |stream_proc:|
            raise StandardError, "API timeout"
          end

          ResponseService.new(message, client_service: client).call

          message.reload
          assert_includes message.content, "Partial reply"
          assert_includes message.content, "Something went wrong while generating a response."
        end

        # --- No tool handler configured ---

        test "returns error string when no execute_tool_block is configured" do
          message = @conversation.messages.create!(role: :assistant, model: @model)

          client = fake_client do |stream_proc:|
            stream_proc.call({
              "type" => "content_block_start",
              "content_block" => { "type" => "tool_use", "id" => "tool_x", "name" => "missing" }
            }, 0)
            stream_proc.call({
              "type" => "content_block_delta",
              "delta" => { "type" => "input_json_delta", "partial_json" => "{}" }
            }, 0)
            stream_proc.call({ "type" => "content_block_stop" }, 0)
            stream_proc.call({ "type" => "message_stop" }, 0)
          end

          configure_tools(
            tools: ->(assistant) { [{ name: "missing" }] },
            execute: nil
          )

          ResponseService.new(message, client_service: client).call

          tool_message = @conversation.messages.where(role: :tool).last
          assert_equal "No tool handler configured.", tool_message.content
        end

        # --- Stopped message ---

        test "does not broadcast response_complete when message is stopped" do
          message = @conversation.messages.create!(role: :assistant, model: @model)

          client = fake_client do |stream_proc:|
            stream_proc.call({ "type" => "content_block_delta", "delta" => { "text" => "Hi" } }, 0)
            stream_proc.call({ "type" => "message_stop" }, 0)
            message.update!(stopped: true)
          end

          ResponseService.new(message, client_service: client).call

          assert message.reload.stopped?
        end

        private

        def fake_client(&block)
          Object.new.tap do |obj|
            obj.define_singleton_method(:call) do |message:, stream_proc:, tools:|
              block.call(stream_proc: stream_proc)
            end
          end
        end

        def configure_tools(tools:, execute:)
          Layered::Assistant.class_variable_set(:@@tools_block, tools)
          Layered::Assistant.class_variable_set(:@@execute_tool_block, execute)
        end
      end
    end
  end
end
