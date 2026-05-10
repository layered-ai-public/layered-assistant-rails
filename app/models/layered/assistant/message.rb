module Layered
  module Assistant
    class Message < ApplicationRecord
      # Includes
      include ActionView::RecordIdentifier

      # UID
      has_secure_token :uid

      # Enums
      enum :role, {
        system: "system",
        assistant: "assistant",
        user: "user"
      }

      # Validations
      validates :content, presence: true, unless: :assistant?

      # Associations
      belongs_to :conversation, counter_cache: true
      belongs_to :model, optional: true, counter_cache: true

      # Scopes
      scope :by_created_at, -> { order(created_at: :asc, id: :asc) }

      # Derived metrics
      MIN_RESPONSE_MS_FOR_TPS = 100

      def total_tokens
        input_tokens.to_i + output_tokens.to_i
      end

      def tokens_per_second
        return unless output_tokens.to_i > 0 && response_ms.to_i >= MIN_RESPONSE_MS_FOR_TPS

        (output_tokens * 1000.0 / response_ms).round(1)
      end

      # Broadcasting
      def broadcast_created
        broadcast_append_to conversation,
          targets: ".#{dom_id(conversation)}_messages",
          partial: "layered/assistant/messages/message",
          locals: { message: self }
      end

      def broadcast_updated
        broadcast_replace_to conversation,
          targets: ".#{dom_id(self)}",
          partial: "layered/assistant/messages/message",
          locals: { message: self }
      end

      def broadcast_response_complete
        broadcast_action_to conversation,
          action: :enable_composer,
          targets: ".#{dom_id(conversation)}_composer"
      end

      def broadcast_streaming_content
        broadcast_action_to conversation,
          action: :render_content,
          targets: ".#{dom_id(self)}_content",
          content: content
      end
    end
  end
end
