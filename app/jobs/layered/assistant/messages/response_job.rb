module Layered
  module Assistant
    module Messages
      class ResponseJob < ApplicationJob
        queue_as :default

        MAX_TOOL_ITERATIONS = 10

        def perform(message_id)
          message = Message.includes(model: :provider, conversation: [:assistant, :messages]).find(message_id)

          unless message.model&.provider
            message.update(content: "No provider is configured for this model.")
            message.broadcast_updated
            message.broadcast_response_complete
            return
          end

          provider = message.model.provider
          conversation = message.conversation
          assistant = conversation.assistant
          tools = resolve_tools(assistant)

          begin
            iterations = 0

            loop do
              iterations += 1
              chunk_service = ChunkService.new(message, provider: provider)

              stream_proc = proc do |chunk, _bytesize|
                chunk_service.call(chunk)
              end

              chunk_service.mark_started!
              ClientService.new.call(message: message, stream_proc: stream_proc, tools: tools)

              pending = chunk_service.accumulated_tool_calls
              break if pending.empty?
              break if iterations >= MAX_TOOL_ITERATIONS

              # Save tool calls on the assistant message
              message.update!(tool_calls: pending.to_json)
              message.broadcast_updated

              # Execute each tool and create result messages
              pending.each do |tc|
                result = execute_tool(tc["name"], tc["input"], assistant: assistant, conversation: conversation, message: message)
                conversation.messages.create!(
                  role: :tool,
                  content: result.to_s,
                  tool_call_id: tc["id"]
                )
              end

              # Create a new assistant message for the next LLM turn
              message = conversation.messages.create!(
                role: :assistant,
                model: message.model
              )
              message.broadcast_created
            end
          rescue => e
            Rails.logger.error("Response generation failed: #{e.message}")
            existing = message.reload.content
            error_note = "Something went wrong while generating a response."
            message.update(content: existing.present? ? "#{existing}\n\n---\n\n#{error_note}" : error_note)
            message.broadcast_updated
          end

          message.broadcast_response_complete unless message.reload.stopped?
        end

        private

        def resolve_tools(assistant)
          return nil unless Layered::Assistant.tools_block

          tools = Layered::Assistant.tools_block.call(assistant)
          tools.presence
        end

        def execute_tool(name, input, context)
          return "No tool handler configured." unless Layered::Assistant.execute_tool_block

          Layered::Assistant.execute_tool_block.call(name, input, context)
        rescue => e
          Rails.logger.error("Tool execution failed for #{name}: #{e.message}")
          "Tool execution failed: #{e.message}"
        end
      end
    end
  end
end
