module Layered
  module Assistant
    module Panel
      class ConversationsController < ApplicationController
        include StoppableResponse
        layout false

        before_action :set_conversation, only: [ :show, :destroy, :stop ]
        before_action :set_conversations, only: [ :index, :show ]
        before_action :set_assistants, only: [ :index, :show, :new, :create ]

        def index
        end

        def show
          @messages = @conversation.messages.includes(:model).by_created_at
          @models = Model.available
          @selected_model_id = @messages.last&.model_id || @conversation.assistant.default_model_id || @models.first&.id
        end

        def new
          @conversation = Conversation.new
        end

        def create
          @conversation = Conversation.new(conversation_params)
          @conversation.owner = l_ui_current_user
          @conversation.assistant = Assistant.owned_by(l_ui_current_user).find(conversation_params[:assistant_id]) if conversation_params[:assistant_id].present?
          @conversation.name = Conversation.default_name if @conversation.name.blank?

          if @conversation.save
            redirect_to layered_assistant.panel_conversation_path(@conversation)
          else
            render :new, status: :unprocessable_entity
          end
        end

        def destroy
          @conversation.destroy
          redirect_to layered_assistant.panel_conversations_path
        end

        private

        def set_conversation
          @conversation = Conversation.owned_by(l_ui_current_user).find(params[:id])
        end

        def set_assistants
          @assistants = Assistant.owned_by(l_ui_current_user).by_name
        end

        def set_conversations
          scope = Conversation.owned_by(l_ui_current_user).by_created_at
          scope = scope.where(assistant_id: params[:assistant_id]) if params[:assistant_id].present?
          @conversations = scope.limit(20)
        end

        def conversation_params
          params.require(:conversation).permit(:assistant_id, :name)
        end
      end
    end
  end
end
