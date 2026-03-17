module Layered
  module Assistant
    module Clients
      class Anthropic < Base
        def chat(messages:, model:, stream_proc:, system_prompt: nil)
          formatted = MessagesService.new.format(messages, provider: @provider, system_prompt: system_prompt)

          parameters = {
            model: model,
            messages: formatted[:messages],
            max_tokens: 8192,
            stream: stream_proc
          }
          parameters[:system] = formatted[:system] if formatted[:system].present?

          ::Anthropic::Client.new(
            access_token: @api_key,
            log_errors: Layered::Assistant.log_errors
          ).messages(parameters: parameters)
        end
      end
    end
  end
end
