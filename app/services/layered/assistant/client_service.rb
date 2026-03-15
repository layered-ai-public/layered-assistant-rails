module Layered
  module Assistant
    class ClientService
      def call(message:, stream_proc:)
        provider = message.model.provider
        client = Clients::Base.for(provider)
        system_prompt = message.conversation.assistant.system_prompt

        client.chat(
          messages: message.conversation.messages,
          model: message.model.identifier,
          stream_proc: stream_proc,
          system_prompt: system_prompt
        )
      end
    end
  end
end
