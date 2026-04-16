module Layered
  module Assistant
    module Clients
      class OpenAI < Base
        def chat(messages:, model:, stream_proc:, tools: nil)
          formatted = MessagesService.new.format(messages, provider: @provider)

          client_options = {
            access_token: @api_key,
            log_errors: Layered::Assistant.log_errors,
            request_timeout: Layered::Assistant.api_request_timeout
          }
          if @provider.url.present?
            client_options[:uri_base] = @provider.url.sub(/\/\z/, "")
            client_options[:api_version] = ""  # Gemini and other OpenAI-compatible APIs use their own path
          end

          parameters = {
            model: model,
            messages: formatted[:messages],
            stream: stream_proc,
            stream_options: { include_usage: true }
          }

          if tools.present?
            parameters[:tools] = tools.map do |t|
              { type: "function", function: { name: t[:name], description: t[:description], parameters: t[:input_schema] } }
            end
          end

          ::OpenAI::Client.new(**client_options) do |f|
            if Layered::Assistant.log_errors
              f.response :logger, Logger.new($stdout), bodies: true
            end
          end.chat(parameters: parameters)
        end
      end
    end
  end
end
