module Layered
  module Assistant
    class PersonasController < ApplicationController
      before_action :set_persona, only: [:edit, :update, :destroy]

      def index
        @page_title = "Personas"
        @pagy, @personas = pagy(scoped(Persona).by_name)
      end

      def new
        @page_title = "New persona"
        @persona = Persona.new
      end

      def create
        @persona = Persona.new(persona_params)

        if @persona.save
          redirect_to layered_assistant.personas_path, notice: "Persona was successfully created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        @page_title = "Edit persona"
      end

      def update
        if @persona.update(persona_params)
          redirect_to layered_assistant.personas_path, notice: "Persona was successfully updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @persona.destroy!
        redirect_to layered_assistant.personas_path, notice: "Persona was successfully deleted."
      rescue ActiveRecord::DeleteRestrictionError, ActiveRecord::InvalidForeignKey
        redirect_to layered_assistant.personas_path, alert: "Persona could not be deleted because it is assigned to assistants."
      end

      private

      def set_persona
        @persona = scoped(Persona).find(params[:id])
      end

      def persona_params
        params.require(:persona).permit(:name, :description, :instructions)
      end
    end
  end
end
