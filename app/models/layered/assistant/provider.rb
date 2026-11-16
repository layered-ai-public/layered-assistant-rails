module Layered
  module Assistant
    class Provider < ApplicationRecord
      include Ownable

      # Virtual attributes
      # `create_models` backs the model-seeding choice on the new provider
      # form: ProviderResource.build_record defaults it to "1" and the field
      # reads it back to preselect that option. ProvidersController#create
      # reads the posted value straight from params, so this accessor looks
      # unused from the controller side - it is not.
      attr_accessor :create_models

      # Set by the provider forms (see ProviderResource) so a key the
      # provider refuses is caught before it is saved. Off everywhere else,
      # so seeds, consoles and tests never call out to a provider.
      attr_accessor :check_secret

      # Positioning
      positioned

      # Associations
      has_many :models, dependent: :destroy

      # Enums
      enum :protocol, {
        anthropic: "anthropic",
        openai: "openai"
      }

      # Encryption
      unless Layered::Assistant.skip_db_encryption
        encrypts :secret
      end

      # Validations
      validates :name, :protocol, presence: true
      validates :url, format: { with: /\Ahttps?:\/\//i, message: "must start with http:// or https://" }, allow_blank: true
      validate :secret_must_be_accepted, if: :check_secret?

      TEMPLATES = {
        "Cloud" => [
          { key: "anthropic", name: "Anthropic", description: "Claude family of models. Requires an API key.", protocol: "anthropic", url: "https://api.anthropic.com/v1", keys_url: "https://console.anthropic.com/settings/keys" },
          { key: "openai", name: "OpenAI", description: "GPT family of models. Requires an API key.", protocol: "openai", url: "https://api.openai.com/v1", keys_url: "https://platform.openai.com/api-keys" },
          { key: "gemini", name: "Gemini", description: "Google Gemini family of models. Requires an API key.", protocol: "openai", url: "https://generativelanguage.googleapis.com/v1beta/openai/", keys_url: "https://aistudio.google.com/api-keys" },
          { key: "mistral", name: "Mistral", description: "Mistral's own frontier models. Requires an API key.", protocol: "openai", url: "https://api.mistral.ai/v1", keys_url: "https://admin.mistral.ai/organization/api-keys" },
          { key: "openrouter", name: "OpenRouter", description: "Access hundreds of models through a single API. Requires an API key.", protocol: "openai", url: "https://openrouter.ai/api/v1/", keys_url: "https://openrouter.ai/settings/keys" },
          { key: "together", name: "Together AI", description: "Serverless inference for open-weight models. Requires an API key.", protocol: "openai", url: "https://api.together.ai/v1", keys_url: "https://api.together.ai/settings/projects/~current/api-keys" },
          { key: "groq", name: "Groq", description: "Low-latency inference for popular open-weight models. Requires an API key.", protocol: "openai", url: "https://api.groq.com/openai/v1", keys_url: "https://console.groq.com/keys" },
          { key: "fireworks", name: "Fireworks", description: "Serverless inference for open-weight models. Requires an API key.", protocol: "openai", url: "https://api.fireworks.ai/inference/v1", keys_url: "https://app.fireworks.ai/settings/users/api-keys" }
        ],
        "Local" => [
          { key: "ollama", name: "Ollama", description: "Run open-weight models locally via the Ollama CLI. No API key required.", protocol: "openai", url: "http://localhost:11434/v1" },
          { key: "lm_studio", name: "LM Studio", description: "Run open-weight models locally via the LM Studio desktop app. No API key required.", protocol: "openai", url: "http://localhost:1234/v1" }
        ]
      }.freeze

      # Scopes
      scope :enabled, -> { where(enabled: true) }
      scope :sorted, -> { order(position: :asc, name: :asc) }

      private

      def check_secret?
        check_secret && secret.present? &&
          (will_save_change_to_secret? || will_save_change_to_protocol? || will_save_change_to_url?)
      end

      # Only a key the provider refused is turned away. One it couldn't be
      # asked about is saved, so an outage doesn't block the form.
      def secret_must_be_accepted
        return if errors.include?(:url) || errors.include?(:protocol)

        check = Providers::KeyCheckService.new(protocol: protocol, url: url, secret: secret).call
        errors.add(:secret, check.message) if check.invalid?
      end
    end
  end
end
