module Layered
  module Assistant
    module Clients
      class Base
        def initialize(provider)
          @provider = provider
          @api_key = provider.secret

          raise StandardError, "API key is not set for provider #{provider.name}" if @api_key.blank?
        end

        def chat(messages:, model:, stream_proc:, system_prompt: nil)
          raise NotImplementedError
        end

        def self.for(provider)
          case provider.protocol
          when "anthropic"
            Clients::Anthropic.new(provider)
          when "openai"
            Clients::OpenAI.new(provider)
          else
            raise StandardError, "Unsupported provider protocol: #{provider.protocol}"
          end
        end
      end
    end
  end
end
