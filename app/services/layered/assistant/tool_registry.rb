module Layered
  module Assistant
    # The tools the host application has made available. The configured block
    # is called on every lookup rather than read once at boot, so tool classes
    # reload in development like any other application class.
    class ToolRegistry
      def self.all
        block = Layered::Assistant.tools_block
        return [] unless block

        Array(block.call).map { |tool| tool.is_a?(String) ? tool.constantize : tool }
      end

      # The subset a conversation may use. A tool that requires an owner is
      # withheld from public conversations, which have none.
      def self.for(conversation)
        all.select { |tool| tool.available_for?(conversation) }
      end

      def self.find(name)
        all.find { |tool| tool.tool_name == name }
      end
    end
  end
end
