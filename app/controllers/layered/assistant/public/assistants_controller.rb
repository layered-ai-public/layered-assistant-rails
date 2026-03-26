module Layered
  module Assistant
    module Public
      class AssistantsController < ApplicationController
        before_action :set_public_assistant, only: [:show]

        def index
          @pagy, @assistants = pagy(Assistant.publicly_available.by_name)
        end

        def show
          conversation = @assistant.conversations.create!(name: Conversation.default_name)
          add_conversation_to_session(conversation)
          redirect_to layered_assistant.public_conversation_path(conversation)
        end
      end
    end
  end
end
