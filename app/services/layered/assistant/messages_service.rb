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
            next if message.content.blank?
            regular_messages << { role: "assistant", content: [ { type: "text", text: message.content } ] }
          end
        end

        result = { messages: regular_messages }
        result[:system] = system_messages.join("\n\n") if system_messages.any?
        result
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
            next if message.content.blank?
            formatted << { role: "assistant", content: message.content }
          end
        end

        { messages: formatted }
      end
    end
  end
end
