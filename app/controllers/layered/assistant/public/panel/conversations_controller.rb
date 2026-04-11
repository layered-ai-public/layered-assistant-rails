module Layered
  module Assistant
    module Public
      module Panel
        class ConversationsController < Public::ApplicationController
          include StoppableResponse
          layout false

          before_action :set_public_assistant, only: [:index, :new, :create]
          before_action :set_conversation, only: [:show, :stop]
          before_action :set_session_conversations, only: [:index, :show]

          def index
          end

          def new
          end

          def create
            @conversation = @assistant.conversations.new(name: Conversation.default_name)

            if @conversation.save
              add_conversation_to_session(@conversation)
              redirect_to layered_assistant.public_panel_conversation_path(@conversation)
            else
              render :new, status: :unprocessable_entity
            end
          end

          def show
            @messages = @conversation.messages.visible.includes(:model).by_created_at
          end

          private

          def set_conversation
            @conversation = find_session_conversation(params[:id])
          rescue ActiveRecord::RecordNotFound
            assistant = Conversation.find_by(uid: params[:id])&.assistant
            if assistant&.public?
              redirect_to layered_assistant.public_panel_conversations_path(assistant_id: assistant.id)
            else
              redirect_to layered_assistant.public_assistants_path
            end
          end

          def set_session_conversations
            assistant_id = @conversation&.assistant_id || @assistant&.id
            @conversations = if session_conversation_uids.any?
              scope = Conversation.joins(:assistant).merge(Assistant.publicly_available)
                .where(uid: session_conversation_uids)
                .by_created_at
              scope = scope.where(assistant_id: assistant_id) if assistant_id
              scope.limit(20)
            else
              Conversation.none
            end
          end
        end
      end
    end
  end
end
