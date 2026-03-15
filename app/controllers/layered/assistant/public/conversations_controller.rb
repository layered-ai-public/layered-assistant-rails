module Layered
  module Assistant
    module Public
      class ConversationsController < ApplicationController
        include StoppableResponse

        before_action :set_public_assistant, only: [:create]
        before_action :set_conversation, only: [:show, :stop]

        def create
          @conversation = @assistant.conversations.new(name: Conversation.default_name)

          if @conversation.save
            add_conversation_to_session(@conversation)
            redirect_to layered_assistant.public_conversation_path(@conversation)
          else
            redirect_to layered_assistant.public_assistant_path(@assistant)
          end
        end

        def show
          @messages = @conversation.messages.includes(:model).by_created_at
        end

        private

        def set_conversation
          @conversation = find_session_conversation(params[:id])
        rescue ActiveRecord::RecordNotFound
          redirect_to layered_assistant.public_assistants_path
        end
      end
    end
  end
end
