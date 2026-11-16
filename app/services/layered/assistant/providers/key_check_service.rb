require "net/http"

module Layered
  module Assistant
    module Providers
      # Asks a provider whether it accepts an API key, with the cheapest call
      # each answers: listing its models. Only the provider refusing the key
      # (400 or 401) marks it invalid. Anything else, from a restricted key
      # without access to the models list (403, or OpenAI's 401 naming the
      # missing scopes) to the provider being down, leaves it unknown, so a
      # key that might work is not turned away.
      class KeyCheckService
        Result = Data.define(:status, :message) do
          def valid? = status == :valid
          def invalid? = status == :invalid
        end

        # Checked as it is typed, so it answers quickly or not at all.
        OPEN_TIMEOUT = 3
        READ_TIMEOUT = 5

        REFUSED = [ 400, 401 ].freeze

        # A refusal for a key that works but can't list models.
        MISSING_PERMISSION = /insufficient permissions|missing scopes/i

        def initialize(protocol:, url:, secret:)
          @protocol = protocol.to_s
          @secret = secret.to_s.strip
          @connection = Connection.new(protocol: protocol, url: url, secret: secret)
        end

        def call
          return result(:unknown, "") if @secret.empty? || !Provider.protocols.key?(@protocol)

          response = @connection.get(check_path, open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT)
          if response.is_a?(Net::HTTPSuccess)
            result(:valid, "The provider accepts this key.")
          elsif REFUSED.include?(response.code.to_i) && !response.body.to_s.match?(MISSING_PERMISSION)
            result(:invalid, "isn't accepted by the provider. Check it and paste it again.")
          else
            unchecked
          end
        rescue StandardError
          unchecked
        end

        private

        # OpenRouter lists its models to anyone, so ask about the key itself.
        def check_path
          URI(@connection.base_url).host == "openrouter.ai" ? "key" : "models"
        end

        def result(status, message) = Result.new(status: status, message: message)

        def unchecked = result(:unknown, "The key couldn't be checked just now.")
      end
    end
  end
end
