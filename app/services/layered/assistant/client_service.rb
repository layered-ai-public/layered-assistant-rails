module Layered
  module Assistant
    class ClientService
      def call(message:, stream_proc:)
        provider = message.model.provider
        conversation = message.conversation
        client = Clients::Base.for(provider)

        client.chat(
          messages: conversation.messages,
          tools: ToolDefinitionsService.new.format(ToolRegistry.for(conversation), provider: provider),
          model: message.model.identifier,
          stream_proc: stream_proc
        )
      end
    end
  end
end
