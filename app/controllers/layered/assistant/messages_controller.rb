module Layered
  module Assistant
    class MessagesController < ApplicationController
      include MessageCreation

      before_action :set_conversation
      before_action :set_message, only: [:destroy]

      def index
        @page_title = "Messages"
        @pagy, @messages = pagy(@conversation.messages.includes(:model).by_created_at)
      end

      def create
        result = create_messages_for(
          conversation: @conversation,
          content: message_params[:content],
          model_id: message_params[:model_id]
        )
        @message = result[:message]

        unless @message.persisted?
          return head :unprocessable_entity
        end

        @assistant_message = result[:assistant_message]
        @models = result[:models]
        @selected_model_id = result[:selected_model_id]
        @error = result[:error]

        respond_to do |format|
          format.turbo_stream
        end
      end

      def destroy
        @message.destroy
        @conversation.update_token_totals!
        redirect_to layered_assistant.conversation_messages_path(@conversation), notice: "Message was successfully deleted."
      end

      private

      def set_conversation
        @conversation = scoped(Conversation).find_by!(uid: params[:conversation_id])
      end

      def set_message
        @message = @conversation.messages.find(params[:id])
      end

      def message_params
        params.require(:message).permit(:content, :model_id)
      end
    end
  end
end
