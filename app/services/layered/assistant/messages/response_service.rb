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
                result = execute_tool(tc["name"], tc["input"], message: message)
                @conversation.messages.create!(
                  role: :tool,
                  content: result.to_s,
                  tool_call_id: tc["id"]
                )
              end

              # Start a new assistant message for the next LLM turn
              message = @conversation.messages.create!(
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

        # Asks the host app for tool definitions via the configured block.
        # Returns nil when no tools are configured, which disables tool use.
        def resolve_tools
          return nil unless Layered::Assistant.tools_block

          tools = Layered::Assistant.tools_block.call(@assistant)
          tools.presence
        end

        # Delegates tool execution to the host app's configured block.
        # Returns a user-friendly error string on failure rather than raising,
        # so the LLM can see the error and recover in its next turn.
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
