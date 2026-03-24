module Layered
  module Assistant
    module Public
      module Panel
        class MessagesController < Public::ApplicationController
          layout false
          include MessageCreation

          before_action :set_conversation

          def create
            result = create_messages_for(
              conversation: @conversation,
              content: message_params[:content],
              model_id: @conversation.assistant.default_model_id
            )
            @message = result[:message]

            unless @message.persisted?
              return head :unprocessable_entity
            end

            @error = result[:error]

            respond_to do |format|
              format.turbo_stream
            end
          end

          private

          def set_conversation
            @conversation = find_session_conversation(params[:conversation_id])
          rescue ActiveRecord::RecordNotFound
            assistant = Conversation.find_by(uid: params[:conversation_id])&.assistant
            if assistant&.public?
              redirect_to layered_assistant.new_public_panel_conversation_path(assistant_id: assistant.id)
            else
              redirect_to layered_assistant.public_assistants_path
            end
          end

          def message_params
            params.require(:message).permit(:content)
          end
        end
      end
    end
  end
end
