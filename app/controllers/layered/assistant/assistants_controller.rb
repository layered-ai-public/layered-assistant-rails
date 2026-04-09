module Layered
  module Assistant
    class AssistantsController < ApplicationController
      before_action :set_assistant, only: [:edit, :update, :destroy]
      before_action :set_models, only: [:new, :create, :edit, :update]
      before_action :set_personas, only: [:new, :create, :edit, :update]
      before_action :set_skills, only: [:new, :create, :edit, :update]

      def index
        @page_title = "Assistants"
        @pagy, @assistants = pagy(scoped(Assistant).includes(:persona, :skills).by_name)
      end

      def new
        @page_title = "New assistant"
        @assistant = Assistant.new
      end

      def create
        @assistant = Assistant.new(assistant_params.except(:persona_id, :skill_ids))
        @assistant.owner = l_ui_current_user
        @assistant.persona = scoped(Persona).find(assistant_params[:persona_id]) if assistant_params[:persona_id].present?
        assign_skills

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
        if assistant_params.key?(:persona_id)
          @assistant.persona = assistant_params[:persona_id].present? ? scoped(Persona).find(assistant_params[:persona_id]) : nil
        end

        assign_skills

        if @assistant.update(assistant_params.except(:persona_id, :skill_ids))
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

      def set_skills
        @skills = scoped(Skill).by_name
      end

      def assign_skills
        if assistant_params.key?(:skill_ids)
          skill_ids = Array(assistant_params[:skill_ids]).compact_blank
          @assistant.skills = scoped(Skill).where(id: skill_ids)
        end
      end

      def assistant_params
        params.require(:assistant).permit(:name, :description, :instructions, :default_model_id, :persona_id, :public, skill_ids: [])
      end
    end
  end
end
