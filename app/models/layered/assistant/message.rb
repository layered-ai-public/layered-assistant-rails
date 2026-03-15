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
      scope :by_created_at, -> { order(created_at: :asc) }

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

      def broadcast_chunk(text)
        broadcast_action_to conversation,
          action: :append_chunk,
          targets: ".#{dom_id(self)}_body",
          content: helpers.content_tag(:span, text, class: "l-ui-token-fade")
      end

      private

      def helpers
        ApplicationController.helpers
      end
    end
  end
end
