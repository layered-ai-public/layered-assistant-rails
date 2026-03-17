module Layered
  module Assistant
    class Provider < ApplicationRecord
      # Virtual attributes
      attr_accessor :create_models

      # Positioning
      positioned

      # Associations
      has_many :models, dependent: :destroy
      belongs_to :owner, polymorphic: true, optional: true

      # Enums
      enum :protocol, {
        anthropic: "anthropic",
        openai: "openai"
      }

      # Encryption
      unless ENV["LAYERED_ASSISTANT_DANGEROUSLY_SKIP_DB_ENCRYPTION"] == "yes"
        encrypts :secret
      end

      # Validations
      validates :name, :protocol, presence: true
      validates :url, format: { with: /\Ahttps?:\/\//i, message: "must start with http:// or https://" }, allow_blank: true

      TEMPLATES = {
        "Cloud" => [
          { key: "anthropic", name: "Anthropic", description: "Claude family of models. Requires an API key.", protocol: "anthropic", url: "https://api.anthropic.com/v1", keys_url: "https://console.anthropic.com/settings/keys" },
          { key: "openai", name: "OpenAI", description: "GPT family of models. Requires an API key.", protocol: "openai", url: "https://api.openai.com/v1", keys_url: "https://platform.openai.com/api-keys" },
          { key: "gemini", name: "Gemini", description: "Google Gemini family of models. Requires an API key.", protocol: "openai", url: "https://generativelanguage.googleapis.com/v1beta/openai/", keys_url: "https://aistudio.google.com/api-keys" },
          { key: "mistral", name: "Mistral", description: "Mistral's own frontier models. Requires an API key.", protocol: "openai", url: "https://api.mistral.ai/v1", keys_url: "https://admin.mistral.ai/organization/api-keys" },
          { key: "groq", name: "Groq", description: "Low-latency inference for popular open-weight models. Requires an API key.", protocol: "openai", url: "https://api.groq.com/openai/v1", keys_url: "https://console.groq.com/keys" },
          { key: "openrouter", name: "OpenRouter", description: "Access hundreds of models through a single API. Requires an API key.", protocol: "openai", url: "https://openrouter.ai/api/v1/", keys_url: "https://openrouter.ai/settings/keys" }
        ],
        "Local" => [
          { key: "ollama", name: "Ollama", description: "Run open-weight models locally via the Ollama CLI. No API key required.", protocol: "openai", url: "http://localhost:11434/v1" },
          { key: "lm_studio", name: "LM Studio", description: "Run open-weight models locally via the LM Studio desktop app. No API key required.", protocol: "openai", url: "http://localhost:1234/v1" }
        ]
      }.freeze

      # Scopes
      scope :enabled, -> { where(enabled: true) }
      scope :sorted, -> { order(position: :asc, name: :asc) }
    end
  end
end
