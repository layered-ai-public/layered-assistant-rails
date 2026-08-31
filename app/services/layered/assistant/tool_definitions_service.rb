module Layered
  module Assistant
    # Renders tool classes into the shape the provider's API expects, the way
    # MessagesService does for conversation history.
    class ToolDefinitionsService
      def format(tools, provider: nil)
        if provider&.protocol == "openai"
          tools.map { |tool| format_openai(tool) }
        else
          tools.map { |tool| format_anthropic(tool) }
        end
      end

      private

      def format_anthropic(tool)
        {
          name: tool.tool_name,
          description: tool.description.to_s,
          input_schema: tool.schema
        }
      end

      def format_openai(tool)
        {
          type: "function",
          function: {
            name: tool.tool_name,
            description: tool.description.to_s,
            parameters: tool.schema
          }
        }
      end
    end
  end
end
