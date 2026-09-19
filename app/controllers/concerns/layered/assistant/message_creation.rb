module Layered
  module Assistant
    module MessageCreation
      WAITING_ON_TOOL_CALL = "A tool call is waiting on you. Answer it before sending another message.".freeze

      private

      def create_messages_for(conversation:, content:, model_id:)
        # A tool call that has yet to reach an answer holds the conversation.
        # The composer is disabled while it waits, so anything arriving here is
        # a stale tab - and answering it would send the model a call with no
        # result yet, which the provider rejects. Said rather than dropped, or
        # the message would vanish with nothing to explain it.
        if conversation.unresolved_tool_call?
          return {
            message: conversation.messages.new(role: :user, content: content),
            error: WAITING_ON_TOOL_CALL,
            responding: true
          }
        end

        message = conversation.messages.create(
          role: :user,
          content: content,
          model_id: model_id,
          input_tokens: TokenEstimator.estimate(content),
          tokens_estimated: true
        )

        return { message: message } unless message.persisted?

        conversation.update_name_from_content!(content)

        assistant_message = nil
        error = nil

        begin
          assistant_message = conversation.messages.create!(
            role: :assistant,
            content: nil,
            model_id: model_id
          )

          message.broadcast_created
          assistant_message.broadcast_created
          Messages::ResponseJob.perform_later(assistant_message.id)
        rescue => e
          Rails.logger.error("Assistant response failed: #{e.message}")
          error = "Something went wrong while generating a response."
        end

        {
          message: message,
          assistant_message: assistant_message,
          error: error,
          responding: error.nil?
        }
      end
    end
  end
end
