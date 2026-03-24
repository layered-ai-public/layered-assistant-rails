module Layered
  module Assistant
    module Panel
      class MessagesController < ApplicationController
        layout false
        include MessageCreation

        before_action :set_conversation

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
          @models = Model.available
          @selected_model_id = message_params[:model_id]
          @error = result[:error]

          respond_to do |format|
            format.turbo_stream
          end
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
end
