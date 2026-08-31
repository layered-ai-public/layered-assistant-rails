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
        user: "user",
        tool: "tool"
      }

      # Validations
      validates :content, presence: true, unless: :assistant?

      # Associations
      belongs_to :conversation, counter_cache: true
      belongs_to :model, optional: true, counter_cache: true

      # Tool calls the model asked for, in the shape ToolCallAccumulator stores:
      # [{ "id" =>, "type" => "function", "function" => { "name" =>, "arguments" => } }]
      def tool_calls
        super || []
      end

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
        broadcast_action_to conversation,
          action: :render_content,
          targets: ".#{dom_id(self)}_content",
          content: content
      end
    end
  end
end
