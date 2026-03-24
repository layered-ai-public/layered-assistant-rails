module Layered
  module Assistant
    module MessageCreation
      private

      def create_messages_for(conversation:, content:, model_id:)
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
          error: error
        }
      end
    end
  end
end
