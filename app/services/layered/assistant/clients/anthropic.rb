module Layered
  module Assistant
    module Clients
      class Anthropic < Base
        def chat(messages:, model:, stream_proc:, tools: nil)
          formatted = MessagesService.new.format(messages, provider: @provider)

          parameters = {
            model: model,
            messages: formatted[:messages],
            max_tokens: 8192,
            stream: stream_proc
          }
          parameters[:system] = formatted[:system] if formatted[:system].present?

          if tools.present?
            parameters[:tools] = tools.map do |t|
              { name: t[:name], description: t[:description], input_schema: t[:input_schema] }
            end
          end

          ::Anthropic::Client.new(
            access_token: @api_key,
            log_errors: Layered::Assistant.log_errors,
            request_timeout: Layered::Assistant.api_request_timeout
          ).messages(parameters: parameters)
        end
      end
    end
  end
end
