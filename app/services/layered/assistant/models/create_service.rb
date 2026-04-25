require "net/http"
require "json"

module Layered
  module Assistant
    module Models
      class CreateService
        MODELS_URL = "https://raw.githubusercontent.com/layered-ai-public/layered-assistant-rails/main/data/models.json".freeze
        LOCAL_MODELS_PATH = Layered::Assistant::Engine.root.join("data", "models.json").freeze

        def initialize(provider)
          @provider = provider
        end

        def call
          models_data = Rails.env.development? ? load_local_models : fetch_models
          return if models_data.nil?

          entries = models_data[@provider.name]
          if entries.nil?
            Rails.logger.info "[layered-ui-assistant] No models found for provider #{@provider.name.inspect} in remote catalogue"
            return
          end

          entries.each do |entry|
            @provider.models.find_or_create_by!(identifier: entry["identifier"]) do |model|
              model.name = entry["name"]
            end
          end
        end

        private

        def load_local_models
          unless File.exist?(LOCAL_MODELS_PATH)
            Rails.logger.info "[layered-ui-assistant] Local model catalogue not found at #{LOCAL_MODELS_PATH} - skipping model sync"
            return nil
          end

          Rails.logger.info "[layered-ui-assistant] Loading model catalogue from local file (development)"
          JSON.parse(File.read(LOCAL_MODELS_PATH))
        end

        def fetch_models
          uri = URI(MODELS_URL)
          response = Net::HTTP.get_response(uri)

          unless response.is_a?(Net::HTTPSuccess)
            Rails.logger.info "[layered-ui-assistant] Could not fetch model catalogue (HTTP #{response.code}) - skipping model sync"
            return nil
          end

          JSON.parse(response.body)
        rescue SocketError, Errno::ECONNREFUSED, Errno::ETIMEDOUT, Net::OpenTimeout, Net::ReadTimeout => e
          Rails.logger.info "[layered-ui-assistant] Could not reach GitHub to fetch model catalogue (#{e.class}) - skipping model sync"
          nil
        end
      end
    end
  end
end
