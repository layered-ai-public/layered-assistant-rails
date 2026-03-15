module Layered
  module Assistant
    module Clients
      class OpenAI < Base
        def chat(messages:, model:, stream_proc:, system_prompt: nil)
          formatted = MessagesService.new.format(messages, provider: @provider, system_prompt: system_prompt)

          client_options = {
            access_token: @api_key,
            log_errors: ENV.fetch("LAYERED_ASSISTANT_LOG_ERRORS", "no") == "yes"
          }
          if @provider.url.present?
            client_options[:uri_base] = @provider.url.sub(/\/\z/, "")
            client_options[:api_version] = ""  # Gemini and other OpenAI-compatible APIs use their own path
          end

          ::OpenAI::Client.new(**client_options) do |f|
            if ENV.fetch("LAYERED_ASSISTANT_LOG_ERRORS", "no") == "yes"
              f.response :logger, Logger.new($stdout), bodies: true
            end
          end.chat(
            parameters: {
              model: model,
              messages: formatted[:messages],
              stream: stream_proc,
              stream_options: { include_usage: true }
            }
          )
        end
      end
    end
  end
end
