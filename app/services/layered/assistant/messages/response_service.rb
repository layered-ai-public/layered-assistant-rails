module Layered
  module Assistant
    module Messages
      # Orchestrates a multi-turn assistant response: streams from the LLM,
      # executes any requested tool calls, and loops until the model is done
      # or the safety cap is reached.
      class ResponseService
        MAX_TOOL_ITERATIONS = 10

        def initialize(message, client_service: ClientService.new)
          @message = message
          @conversation = message.conversation
          @assistant = @conversation.assistant
          @provider = message.model&.provider
          @client_service = client_service
        end

        def call
          unless @provider
            @message.update(content: "No provider is configured for this model.")
            @message.broadcast_updated
            @message.broadcast_response_complete
            return
          end

          tools = resolve_tools
          message = @message

          begin
            iterations = 0

            # Each iteration streams one LLM response. If the response contains
            # tool calls we execute them, append the results to the conversation,
            # create a fresh assistant message, and loop for the follow-up response.
            loop do
              iterations += 1
              chunk_service = ChunkService.new(message, provider: @provider)

              stream_proc = proc do |chunk, _bytesize|
                chunk_service.call(chunk)
              end

              chunk_service.mark_started!
              @client_service.call(message: message, stream_proc: stream_proc, tools: tools)

              # If the LLM didn't request any tools, the response is complete
              pending = chunk_service.accumulated_tool_calls
              break if pending.empty?

              # Guard against runaway tool loops
              if iterations >= MAX_TOOL_ITERATIONS
                Rails.logger.warn("Tool loop hit MAX_TOOL_ITERATIONS (#{MAX_TOOL_ITERATIONS}) for conversation #{@conversation.id}")
                message.update!(content: (message.content.presence || "") + "\n\nTool use limit reached.")
                message.broadcast_updated
                break
              end

              # Persist the tool calls on the assistant message so the full
              # conversation history is available when formatting the next request
              message.update!(tool_calls: pending.to_json)
              message.broadcast_updated

              # Execute each tool and record the result as a tool-role message
              pending.each do |tc|
                result = execute_tool(tc["name"], tc["input"],
                  assistant: @assistant, conversation: @conversation, message: message)
                tool_message = @conversation.messages.create!(
                  role: :tool,
                  content: result.to_s,
                  tool_call_id: tc["id"]
                )
                tool_message.broadcast_created
              end

              # Start a new assistant message for the next LLM turn
              message = @conversation.messages.create!(
                role: :assistant,
                model: message.model
              )
              message.broadcast_created
            end
          rescue StandardError => e
            Rails.logger.error("Response generation failed: #{e.message}")
            existing = message.reload.content
            error_note = "Something went wrong while generating a response."
            message.update(content: existing.present? ? "#{existing}\n\n---\n\n#{error_note}" : error_note)
            message.broadcast_updated
          end

          message.broadcast_response_complete unless message.reload.stopped?
        end

        private

        def resolve_tools
          tools = @assistant.tools.map(&:to_tool_definition)

          if Layered::Assistant.tools_block
            block_tools = Layered::Assistant.tools_block.call(@assistant)
            tools.concat(Array(block_tools)) if block_tools.present?
          end

          tools.presence
        end

        def execute_tool(name, input, context)
          return "No tool handler configured." unless Layered::Assistant.execute_tool_block

          timeout = Layered::Assistant.tool_execution_timeout
          if timeout && timeout > 0
            Timeout.timeout(timeout) do
              Layered::Assistant.execute_tool_block.call(name, input, context)
            end
          else
            Layered::Assistant.execute_tool_block.call(name, input, context)
          end
        rescue Timeout::Error
          Rails.logger.error("Tool execution timed out for #{name} after #{timeout}s")
          "Tool execution timed out after #{timeout}s."
        rescue StandardError => e
          Rails.logger.error("Tool execution failed for #{name}: #{e.message}")
          "Tool execution failed: #{e.message}"
        end
      end
    end
  end
end
