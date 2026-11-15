require "net/http"

module Layered
  module Assistant
    module Providers
      # Asks a provider whether it accepts an API key, with the cheapest call
      # each answers: listing its models. Only the provider refusing the key
      # (400 or 401) marks it invalid. Anything else, from a restricted key
      # without access to the models list (403) to the provider being down,
      # leaves it unknown, so a key that might work is not turned away.
      #
      # The URL is resolved the same way the chat clients resolve it: the
      # Anthropic client always talks to Anthropic, and the OpenAI client
      # appends paths straight onto the provider's URL when one is set.
      class KeyCheckService
        Result = Data.define(:status, :message) do
          def valid? = status == :valid
          def invalid? = status == :invalid
        end

        ANTHROPIC_MODELS_URL = "https://api.anthropic.com/v1/models".freeze
        OPENAI_BASE_URL = "https://api.openai.com/v1".freeze

        # Checked as it is typed, so it answers quickly or not at all.
        OPEN_TIMEOUT = 3
        READ_TIMEOUT = 5

        REFUSED = [ 400, 401 ].freeze

        def initialize(protocol:, url:, secret:)
          @protocol = protocol.to_s
          @url = url.to_s.strip
          @secret = secret.to_s.strip
        end

        def call
          return result(:unknown, "") if @secret.empty? || !Provider.protocols.key?(@protocol)

          response = request
          if response.is_a?(Net::HTTPSuccess)
            result(:valid, "The provider accepts this key.")
          elsif REFUSED.include?(response.code.to_i)
            result(:invalid, "isn't accepted by the provider. Check it and paste it again")
          else
            unchecked
          end
        rescue StandardError
          unchecked
        end

        private

        def request
          uri = URI(check_url)
          get = Net::HTTP::Get.new(uri)
          headers.each { |name, value| get[name] = value }

          Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                          open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT) do |http|
            http.request(get)
          end
        end

        def check_url
          return ANTHROPIC_MODELS_URL if @protocol == "anthropic"

          base = (@url.presence || OPENAI_BASE_URL).sub(/\/\z/, "")
          # OpenRouter lists its models to anyone, so ask about the key itself.
          path = URI(base).host == "openrouter.ai" ? "key" : "models"
          "#{base}/#{path}"
        end

        def headers
          if @protocol == "anthropic"
            { "x-api-key" => @secret, "anthropic-version" => "2023-06-01" }
          else
            { "Authorization" => "Bearer #{@secret}" }
          end
        end

        def result(status, message) = Result.new(status: status, message: message)

        def unchecked = result(:unknown, "The key couldn't be checked just now.")
      end
    end
  end
end
