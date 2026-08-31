module Layered
  module Assistant
    # Runs the tools an assistant message asked for, records a message per
    # result, then queues a fresh assistant message so the model can answer
    # with what the tools returned. That message may ask for tools again,
    # which is the loop max_tool_cycles bounds.
    class ToolRunnerService
      def call(message:)
        return if message.tool_calls.blank?

        conversation = message.conversation
        message.tool_calls.each { |tool_call| record_result(message, tool_call) }
        conversation.update_token_totals!

        if cycles_since_last_prompt(conversation) >= Layered::Assistant.max_tool_cycles
          halt(message)
        else
          continue(message)
        end
      end

      private

      def record_result(message, tool_call)
        name = tool_call.dig("function", "name")
        arguments = tool_call.dig("function", "arguments")
        content = execute(message, name, arguments)

        result = message.conversation.messages.create!(
          role: :tool,
          content: content,
          model_id: message.model_id,
          tool_call_id: tool_call["id"],
          tool_name: name,
          tool_arguments: arguments,
          input_tokens: TokenEstimator.estimate(content),
          tokens_estimated: true
        )
        result.broadcast_created
      end

      # Every failure is reported to the model as the tool's result rather than
      # raised: a bad argument or a missing record is something it can recover
      # from on the next turn.
      def execute(message, name, arguments)
        tool = ToolRegistry.find(name)
        return error("There is no tool called '#{name}'.") unless tool
        return error("The tool '#{name}' is not available in this conversation.") unless tool.available_for?(message.conversation)

        result = tool.new(message: message).call(**tool.cast_arguments(parse(arguments)))
        format_result(result)
      rescue Tool::InvalidArguments => e
        error("The tool was called with invalid arguments: #{e.message}")
      rescue => e
        Rails.logger.error("Tool '#{name}' failed: #{e.class}: #{e.message}")
        error("The tool raised an error: #{e.message}")
      end

      def parse(arguments)
        return {} if arguments.blank?

        JSON.parse(arguments)
      rescue JSON::ParserError
        raise Tool::InvalidArguments, "the arguments were not valid JSON"
      end

      def format_result(result)
        content = result.is_a?(String) ? result : result.to_json
        content.presence || "The tool returned no output."
      end

      def error(reason)
        { error: reason }.to_json
      end

      # One cycle is an assistant message that asked for tools. Counted from
      # the last thing the user said, so each prompt gets a full budget.
      def cycles_since_last_prompt(conversation)
        cutoff = conversation.messages.where(role: :user).maximum(:created_at)
        scope = conversation.messages.where(role: :assistant)
        scope = scope.where(created_at: cutoff..) if cutoff

        scope.count { |message| message.tool_calls.present? }
      end

      def continue(message)
        follow_up = message.conversation.messages.create!(
          role: :assistant,
          content: nil,
          model_id: message.model_id
        )
        follow_up.broadcast_created
        Messages::ResponseJob.perform_later(follow_up.id)
      end

      def halt(message)
        # The notice is the engine talking, not the model, so it costs nothing.
        # Recording that keeps the conversation out of Conversation#responding?,
        # which would otherwise leave the composer disabled on the next load.
        notice = message.conversation.messages.create!(
          role: :assistant,
          content: "I stopped after #{Layered::Assistant.max_tool_cycles} rounds of tool calls without reaching an answer. Please try rephrasing your request.",
          model_id: message.model_id,
          output_tokens: 0,
          tokens_estimated: true
        )
        notice.broadcast_created
        notice.broadcast_response_complete
        Rails.logger.warn("Tool call limit reached for conversation #{message.conversation_id}")
      end
    end
  end
end
