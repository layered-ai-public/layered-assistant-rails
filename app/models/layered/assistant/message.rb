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
        rendered = helpers.render_streaming_markdown(content)
        html = rendered[:html]

        if rendered[:has_unclosed_fence]
          html += helpers.tag.div(
            helpers.tag.span(class: "l-ui-typing-indicator__dot") +
            helpers.tag.span(class: "l-ui-typing-indicator__dot") +
            helpers.tag.span(class: "l-ui-typing-indicator__dot"),
            class: "l-ui-typing-indicator",
            role: "status",
            "aria-label": "Assistant is typing"
          )
        end

        broadcast_action_to conversation,
          action: :render_content,
          targets: ".#{dom_id(self)}_body",
          content: html
      end

      private

      def helpers
        ApplicationController.helpers
      end
    end
  end
end
