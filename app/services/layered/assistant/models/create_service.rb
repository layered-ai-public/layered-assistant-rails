require "json"

module Layered
  module Assistant
    module Models
      # Seeds a provider's models by asking the provider itself, using its own
      # key, which models it offers. Anthropic has its own models endpoint;
      # every other provider speaks the OpenAI protocol and lists its models
      # at `<url>/models`. Models for something other than chat (embeddings,
      # images, speech, live voice and so on) are left out, and only the
      # newest LIMIT are kept, as aggregators such as OpenRouter list hundreds.
      class CreateService
        LIMIT = 20
        OTHER_USES = /audio|realtime|live|transcribe|tts|image|embed|dall-e|whisper|moderation|guard|ocr|davinci|babbage|sora/

        def initialize(provider)
          @provider = provider
          @connection = Providers::Connection.for(provider)
        end

        def call
          models = @connection.anthropic? ? anthropic_models : openai_models
          return if models.nil?

          models.each do |model|
            @provider.models.find_or_create_by!(identifier: model[:identifier]) do |record|
              record.name = model[:name]
            end
          end
        end

        private

        # Newest first, a page at a time.
        def anthropic_models
          models = []
          after = nil

          loop do
            page = get({ limit: 1000, after_id: after }.compact)
            return if page.nil?

            models += page["data"].to_a.map { |model| { identifier: model["id"], name: model["display_name"].presence || model["id"] } }
            break unless page["has_more"]

            after = page["last_id"]
          end

          models.first(LIMIT)
        end

        # OpenAI's list and those like it: `data`, or Together's bare array.
        # Some say what each model is for, as Together's `type` and Mistral's
        # `capabilities` do. Gemini prefixes its ids with "models/". Mistral
        # also lists each alias as its own model, named after the model it
        # points to, so only the first model with each name is kept.
        #
        # Without a `created` date on any model, as with Gemini, there is no
        # telling which are newest, so none are cut.
        def openai_models
          page = get
          return if page.nil?

          models = (page.is_a?(Array) ? page : page["data"].to_a).reject { |model| other_use?(model) }
          limit = models.any? { |model| model["created"].to_i > 0 } ? LIMIT : models.size

          models
            .each_with_index
            .sort_by { |model, index| [ -model["created"].to_i, index ] }
            .map(&:first)
            .map do |model|
              identifier = model["id"].to_s.delete_prefix("models/")
              { identifier: identifier, name: model["display_name"].presence || model["name"].presence || identifier }
            end
            .uniq { |model| model[:name] }
            .first(limit)
        end

        # Mistral's `type` says whether a model is base or fine-tuned, not
        # what it is for, so `capabilities` is trusted first when given.
        def other_use?(model)
          return true if model["id"].to_s.match?(OTHER_USES)
          return model["capabilities"]["completion_chat"] == false if model["capabilities"].is_a?(Hash)

          model.key?("type") && model["type"] != "chat"
        end

        def get(params = {})
          response = @connection.get("models", params, open_timeout: 5, read_timeout: 15)

          unless response.is_a?(Net::HTTPSuccess)
            Rails.logger.info "[layered-assistant] Could not list models for provider #{@provider.name.inspect} (HTTP #{response.code}) - skipping model sync"
            return nil
          end

          JSON.parse(response.body)
        rescue SocketError, SystemCallError, IOError, OpenSSL::SSL::SSLError, Timeout::Error, JSON::ParserError, URI::InvalidURIError => e
          Rails.logger.info "[layered-assistant] Could not list models for provider #{@provider.name.inspect} (#{e.class}) - skipping model sync"
          nil
        end
      end
    end
  end
end
