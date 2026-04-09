module Layered
  module Assistant
    class SkillsController < ApplicationController
      before_action :set_skill, only: [:edit, :update, :destroy]

      def index
        @page_title = "Skills"
        @pagy, @skills = pagy(scoped(Skill).by_name)
      end

      def new
        @page_title = "New skill"
        @skill = Skill.new
      end

      def create
        @skill = Skill.new(skill_params)
        @skill.owner = l_ui_current_user

        if @skill.save
          redirect_to layered_assistant.skills_path, notice: "Skill was successfully created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        @page_title = "Edit skill"
      end

      def update
        if @skill.update(skill_params)
          redirect_to layered_assistant.skills_path, notice: "Skill was successfully updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        if @skill.destroy
          redirect_to layered_assistant.skills_path, notice: "Skill was successfully deleted."
        else
          redirect_to layered_assistant.skills_path, alert: "Skill could not be deleted: #{@skill.errors.full_messages.to_sentence}."
        end
      rescue ActiveRecord::InvalidForeignKey
        redirect_to layered_assistant.skills_path, alert: "Skill could not be deleted because it is assigned to assistants."
      end

      private

      def set_skill
        @skill = scoped(Skill).find(params[:id])
      end

      def skill_params
        params.require(:skill).permit(:name, :description, :instructions)
      end
    end
  end
end
