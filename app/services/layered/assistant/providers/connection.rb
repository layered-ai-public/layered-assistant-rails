require "net/http"

module Layered
  module Assistant
    module Providers
      # How to reach a provider's API with its key, resolved the same way the
      # chat clients resolve it: the Anthropic client always talks to
      # Anthropic, and the OpenAI client appends paths straight onto the
      # provider's URL when one is set, or OpenAI's otherwise.
      class Connection
        ANTHROPIC_BASE_URL = "https://api.anthropic.com/v1".freeze
        OPENAI_BASE_URL = "https://api.openai.com/v1".freeze

        def self.for(provider)
          new(protocol: provider.protocol, url: provider.url, secret: provider.secret)
        end

        def initialize(protocol:, url:, secret:)
          @protocol = protocol.to_s
          @url = url.to_s.strip
          @secret = secret.to_s.strip
        end

        def anthropic? = @protocol == "anthropic"

        def base_url
          return ANTHROPIC_BASE_URL if anthropic?

          (@url.presence || OPENAI_BASE_URL).sub(%r{/\z}, "")
        end

        # Local providers such as Ollama take no key, so none is sent.
        def headers
          if anthropic?
            { "x-api-key" => @secret, "anthropic-version" => "2023-06-01" }
          elsif @secret.present?
            { "Authorization" => "Bearer #{@secret}" }
          else
            {}
          end
        end

        # Network errors are raised, as callers handle them differently.
        def get(path, params = {}, open_timeout:, read_timeout:)
          uri = URI("#{base_url}/#{path}")
          uri.query = URI.encode_www_form(params) if params.any?

          Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                          open_timeout: open_timeout, read_timeout: read_timeout) do |http|
            http.get(uri.request_uri, headers)
          end
        end
      end
    end
  end
end
