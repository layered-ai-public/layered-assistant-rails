module Layered
  module Assistant
    # Messages are a layered resource for listing and deleting them; only
    # `create` - the composer posting a message - is this engine's own.
    class MessagesController < ResourcesController
      include MessageCreation

      # Messages have no fields, which the gem reads as having no form, but
      # `create` is the composer's rather than the gem's.
      skip_before_action :require_layered_fields, only: [ :create ]
      before_action :set_conversation, only: [ :create, :destroy ]

      def create
        model_id = scoped_model_id(message_params[:model_id])

        result = create_messages_for(
          conversation: @conversation,
          content: message_params[:content],
          model_id: model_id
        )
        @message = result[:message]
        @error = result[:error]
        @responding = result[:responding]

        unless @message.persisted? || @error
          return head :unprocessable_entity
        end

        @assistant_message = result[:assistant_message]
        @models = scoped_models
        @selected_model_id = model_id

        respond_to do |format|
          format.turbo_stream
        end
      end

      def destroy
        super
        @conversation.update_token_totals!
      end

      private

      def set_conversation
        @conversation = scoped(Conversation).find_by!(uid: params[:conversation_id])
      end

      def message_params
        params.require(:message).permit(:content, :model_id)
      end
    end
  end
end
