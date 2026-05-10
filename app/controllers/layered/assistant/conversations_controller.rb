module Layered
  module Assistant
    class ConversationsController < ResourcesController
      include StoppableResponse

      skip_before_action :load_layered_resource, only: [ :show, :stop ]
      skip_before_action :load_layered_member_record, only: [ :show, :stop ]
      skip_before_action :set_layered_page_title, only: [ :show, :stop ]

      before_action :set_conversation, only: [ :show, :edit, :update, :destroy, :stop ]
      before_action :set_assistants, only: [ :new, :create ]

      def show
        @page_title = @conversation.name
        @messages = @conversation.messages.includes(:model).by_created_at
        @models = Model.available
        @selected_model_id = @messages.last&.model_id || @conversation.assistant.default_model_id || @models.first&.id
      end

      def create
        @record = @resource.build_record(self)
        @record.owner = l_ui_current_user
        if conversation_params[:assistant_id].present?
          @record.assistant = Assistant.owned_by(l_ui_current_user).find(conversation_params[:assistant_id])
        end
        @record.assign_attributes(conversation_params.except(:assistant_id))
        @record.name = Conversation.default_name if @record.name.blank?

        if @record.save
          redirect_to layered_assistant.conversation_path(@record)
        else
          @form_url = layered_collection_path
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        @record = @conversation
        @form_url = layered_member_path(@conversation)
        @page_title = "Edit conversation"
      end

      def update
        if @conversation.update(conversation_params.except(:assistant_id))
          redirect_to @resource.after_save_path(self, @conversation),
            notice: t("layered.resource.flash.updated", model: @resource.model.model_name.human)
        else
          @record = @conversation
          @form_url = layered_member_path(@conversation)
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @conversation.destroy
        redirect_to @resource.after_save_path(self, @conversation),
          notice: t("layered.resource.flash.deleted", model: @resource.model.model_name.human)
      end

      private

      def set_conversation
        @conversation = Conversation.owned_by(l_ui_current_user).find(params[:id])
      end

      def set_assistants
        @assistants = Assistant.owned_by(l_ui_current_user).by_name
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
