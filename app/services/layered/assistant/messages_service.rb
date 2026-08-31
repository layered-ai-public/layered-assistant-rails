module Layered
  module Assistant
    class MessagesService
      def format(messages, provider: nil)
        protocol = provider&.protocol

        if protocol == "openai"
          format_openai(messages)
        else
          format_anthropic(messages)
        end
      end

      private

      def format_anthropic(messages)
        system_messages = []
        regular_messages = []

        messages.by_created_at.each do |message|
          case message.role
          when "system"
            system_messages << message.content
          when "user"
            regular_messages << { role: "user", content: [ { type: "text", text: message.content } ] }
          when "assistant"
            blocks = anthropic_assistant_blocks(message)
            next if blocks.empty?
            regular_messages << { role: "assistant", content: blocks }
          when "tool"
            append_tool_result(regular_messages, message)
          end
        end

        result = { messages: regular_messages }
        result[:system] = system_messages.join("\n\n") if system_messages.any?
        result
      end

      # An assistant turn is text, tool calls, or both. One with neither is the
      # message currently being streamed, which has nothing to send yet.
      def anthropic_assistant_blocks(message)
        blocks = []
        blocks << { type: "text", text: message.content } if message.content.present?

        message.tool_calls.each do |tool_call|
          blocks << {
            type: "tool_use",
            id: tool_call["id"],
            name: tool_call.dig("function", "name"),
            input: parse_arguments(tool_call.dig("function", "arguments"))
          }
        end

        blocks
      end

      # Anthropic expects every result for an assistant turn in the single user
      # message that follows it, so consecutive results are merged into one.
      def append_tool_result(regular_messages, message)
        block = { type: "tool_result", tool_use_id: message.tool_call_id, content: message.content }
        previous = regular_messages.last

        if previous && previous[:role] == "user" && previous.dig(:content, 0, :type) == "tool_result"
          previous[:content] << block
        else
          regular_messages << { role: "user", content: [ block ] }
        end
      end

      def format_openai(messages)
        formatted = []

        messages.by_created_at.each do |message|
          case message.role
          when "system"
            formatted << { role: "system", content: message.content }
          when "user"
            formatted << { role: "user", content: message.content }
          when "assistant"
            next if message.content.blank? && message.tool_calls.empty?
            entry = { role: "assistant", content: message.content }
            entry[:tool_calls] = message.tool_calls if message.tool_calls.any?
            formatted << entry
          when "tool"
            formatted << { role: "tool", tool_call_id: message.tool_call_id, content: message.content }
          end
        end

        { messages: formatted }
      end

      def parse_arguments(arguments)
        return {} if arguments.blank?

        parsed = JSON.parse(arguments)
        parsed.is_a?(Hash) ? parsed : {}
      rescue JSON::ParserError
        {}
      end
    end
  end
end
