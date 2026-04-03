module Layered
  module Assistant
    class AssistantsController < ApplicationController
      before_action :set_assistant, only: [:edit, :update, :destroy]
      before_action :set_models, only: [:new, :create, :edit, :update]
      before_action :set_personas, only: [:new, :create, :edit, :update]

      def index
        @page_title = "Assistants"
        @pagy, @assistants = pagy(scoped(Assistant).by_name)
      end

      def new
        @page_title = "New assistant"
        @assistant = Assistant.new
      end

      def create
        @assistant = Assistant.new(assistant_params)
        @assistant.owner = l_ui_current_user

        if @assistant.save
          redirect_to layered_assistant.assistants_path, notice: "Assistant was successfully created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        @page_title = "Edit assistant"
      end

      def update
        if @assistant.update(assistant_params)
          redirect_to layered_assistant.assistants_path, notice: "Assistant was successfully updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @assistant.destroy
        redirect_to layered_assistant.assistants_path, notice: "Assistant was successfully deleted."
      end

      private

      def set_assistant
        @assistant = scoped(Assistant).find(params[:id])
      end

      def set_models
        @models = Model.available
      end

      def set_personas
        @personas = scoped(Persona).by_name
      end

      def assistant_params
        params.require(:assistant).permit(:name, :description, :instructions, :default_model_id, :persona_id, :public)
      end
    end
  end
end
