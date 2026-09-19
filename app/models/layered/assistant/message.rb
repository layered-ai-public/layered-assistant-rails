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

      # Where a tool call that asked for consent has got to. Null for a call
      # that ran unattended, which is most of them.
      enum :tool_status, {
        pending: "pending",
        approved: "approved",
        declined: "declined"
      }, prefix: :consent

      # Validations
      # A tool call under consent is written in two steps - the decision is
      # recorded, then the call runs and its answer is written - so it holds
      # no content in between. Every other tool message has its answer from
      # the moment it exists.
      validates :content, presence: true, unless: -> { assistant? || under_consent? }

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

      # Whether this message is a tool call that was put to the person
      # talking, whatever they said to it.
      def under_consent?
        tool_status.present?
      end

      # Writes the outcome of a call that was waiting to be approved. Until
      # this runs the message is the question; afterwards it is the answer,
      # and reads like any other tool message.
      #
      # Conditional on the call still being unanswered, because stopping the
      # response answers a waiting call on its behalf: whichever gets there
      # first wins, and the loser is told so rather than overwriting it.
      def resolve_tool_call!(status:, content:)
        written = self.class.where(id: id, content: nil).update_all(
          tool_status: status,
          content: content,
          input_tokens: TokenEstimator.estimate(content),
          tokens_estimated: true,
          updated_at: Time.current
        )
        return false if written.zero?

        reload
        true
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

      # Tells the composer the response is not lost, only waiting: it holds
      # its ground rather than giving up on a response that is doing exactly
      # what it should - nothing, until the call is answered.
      def broadcast_response_waiting
        broadcast_action_to conversation,
          action: :wait_composer,
          targets: ".#{dom_id(conversation)}_composer"
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
