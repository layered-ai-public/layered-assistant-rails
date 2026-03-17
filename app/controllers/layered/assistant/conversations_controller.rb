module Layered
  module Assistant
    class ConversationsController < ApplicationController
      include StoppableResponse

      before_action :set_conversation, only: [:show, :edit, :update, :destroy, :stop]
      before_action :set_assistants, only: [:new, :create]

      def index
        if params[:assistant_id]
          @assistant = scoped(Assistant).find(params[:assistant_id])
          @page_title = "Conversations - #{@assistant.name}"
          @pagy, @conversations = pagy(@assistant.conversations.merge(scoped(Conversation)).includes(:owner).by_created_at)
        else
          @page_title = "Conversations"
          @pagy, @conversations = pagy(scoped(Conversation).includes(:assistant, :owner).by_created_at)
        end
      end

      def show
        @page_title = @conversation.name
        @messages = @conversation.messages.includes(:model).by_created_at
        @models = Model.available
        @selected_model_id = @messages.last&.model_id || @conversation.assistant.default_model_id || @models.first&.id
      end

      def new
        @page_title = "New conversation"
        @conversation = Conversation.new(params.permit(conversation: [:assistant_id])[:conversation])
      end

      def create
        @conversation = Conversation.new(conversation_params)
        @conversation.owner = l_ui_current_user
        @conversation.name = Conversation.default_name if @conversation.name.blank?
        if @conversation.save
          redirect_to layered_assistant.conversation_path(@conversation), notice: "Conversation was successfully created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        @page_title = "Edit conversation"
      end

      def update
        if @conversation.update(conversation_params)
          redirect_to layered_assistant.conversations_path, notice: "Conversation was successfully updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @conversation.destroy
        redirect_to layered_assistant.conversations_path, notice: "Conversation was successfully deleted."
      end

      private

      def set_conversation
        @conversation = scoped(Conversation).find(params[:id])
      end

      def set_assistants
        @assistants = scoped(Assistant).by_name
      end

      def conversation_params
        if action_name == "create"
          params.require(:conversation).permit(:name, :assistant_id)
        else
          params.require(:conversation).permit(:name)
        end
      end
    end
  end
end
