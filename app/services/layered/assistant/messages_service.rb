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
            regular_messages << { role: "user", content: [{ type: "text", text: message.content }] }
          when "assistant"
            formatted = format_anthropic_assistant(message)
            regular_messages << formatted if formatted
          when "tool"
            # Anthropic expects tool results inside a user-role message
            regular_messages << {
              role: "user",
              content: [{ type: "tool_result", tool_use_id: message.tool_call_id, content: message.content || "" }]
            }
          end
        end

        result = { messages: regular_messages }
        result[:system] = system_messages.join("\n\n") if system_messages.any?
        result
      end

      def format_anthropic_assistant(message)
        content = []
        content << { type: "text", text: message.content } if message.content.present?

        if message.tool_calls.present?
          parsed = message.tool_calls.is_a?(String) ? JSON.parse(message.tool_calls) : message.tool_calls
          parsed.each do |tc|
            content << { type: "tool_use", id: tc["id"], name: tc["name"], input: tc["input"] || {} }
          end
        end

        return nil if content.empty?
        { role: "assistant", content: content }
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
            next if message.content.blank? && message.tool_calls.blank?
            entry = { role: "assistant", content: message.content }
            if message.tool_calls.present?
              parsed = message.tool_calls.is_a?(String) ? JSON.parse(message.tool_calls) : message.tool_calls
              entry[:tool_calls] = parsed.map do |tc|
                { id: tc["id"], type: "function", function: { name: tc["name"], arguments: (tc["input"] || {}).to_json } }
              end
            end
            formatted << entry
          when "tool"
            formatted << { role: "tool", tool_call_id: message.tool_call_id, content: message.content || "" }
          end
        end

        { messages: formatted }
      end
    end
  end
end
