module Layered
  module Assistant
    class ClientService
      def call(message:, stream_proc:, tools: nil)
        provider = message.model.provider
        client = Clients::Base.for(provider)

        client.chat(
          messages: message.conversation.messages,
          model: message.model.identifier,
          stream_proc: stream_proc,
          tools: tools
        )
      end
    end
  end
end
