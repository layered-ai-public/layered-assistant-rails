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

      # The subset a conversation may use: the tools its assistant has been
      # given, minus any the conversation cannot reach. A tool that requires
      # an owner is withheld from public conversations, which have none.
      #
      # An assistant with no tools selected calls nothing. Names that no
      # longer match a registered class simply drop out, so a tool removed
      # from the application does not break the assistants that listed it.
      def self.for(conversation)
        names = conversation&.assistant&.tool_names
        return [] if names.blank?

        all.select { |tool| names.include?(tool.tool_name) && tool.available_for?(conversation) }
      end

      # Whether a conversation may call the named tool. The runner asks
      # before executing, so a model that invents a call to a tool its
      # assistant was not given gets an error back rather than a result.
      def self.available?(tool, conversation)
        self.for(conversation).include?(tool)
      end

      def self.find(name)
        all.find { |tool| tool.tool_name == name }
      end
    end
  end
end
