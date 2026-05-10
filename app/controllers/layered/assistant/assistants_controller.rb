module Layered
  module Assistant
    class AssistantsController < ResourcesController
      before_action :set_form_collections, only: [ :new, :create, :edit, :update ]

      def create
        @record = @resource.build_record(self)
        @record.persona = scoped_persona if assistant_params[:persona_id].present?
        @record.assign_attributes(assistant_params.except(:persona_id, :skill_ids))

        if @record.save
          assign_skills
          redirect_to @resource.after_save_path(self, @record),
            notice: t("layered.resource.flash.created", model: @resource.model.model_name.human)
        else
          @form_url = layered_collection_path
          render :new, status: :unprocessable_entity
        end
      end

      def update
        @record = @resource.scope(self).find(params[:id])

        if assistant_params.key?(:persona_id)
          @record.persona = assistant_params[:persona_id].present? ? scoped_persona : nil
        end

        if @record.update(assistant_params.except(:persona_id, :skill_ids))
          assign_skills
          redirect_to @resource.after_save_path(self, @record),
            notice: t("layered.resource.flash.updated", model: @resource.model.model_name.human)
        else
          @form_url = layered_member_path(@record)
          render :edit, status: :unprocessable_entity
        end
      end

      private

      def set_form_collections
        @models = Model.available
        @personas = Persona.owned_by(l_ui_current_user).by_name
        @skills = Skill.owned_by(l_ui_current_user).by_name
      end

      def scoped_persona
        Persona.owned_by(l_ui_current_user).find(assistant_params[:persona_id])
      end

      def assign_skills
        return unless assistant_params.key?(:skill_ids)
        skill_ids = Array(assistant_params[:skill_ids]).compact_blank
        @record.skills = Skill.owned_by(l_ui_current_user).where(id: skill_ids)
      end

      def assistant_params
        params.require(:assistant).permit(
          :name, :description, :instructions, :default_model_id, :persona_id, :public,
          skill_ids: []
        )
      end
    end
  end
end
