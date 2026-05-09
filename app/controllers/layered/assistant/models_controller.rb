module Layered
  module Assistant
    class ModelsController < ApplicationController
      before_action :set_provider
      before_action :set_model, only: [ :edit, :update, :destroy ]

      def index
        @pagy, @models = pagy(@provider.models.sorted)
      end

      def new
        @model = @provider.models.new
      end

      def create
        @model = @provider.models.new(model_params)

        if @model.save
          redirect_to layered_assistant.provider_models_path(@provider), notice: "Model was successfully created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
      end

      def update
        if @model.update(model_params)
          redirect_to layered_assistant.provider_models_path(@provider), notice: "Model was successfully updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        if @model.destroy
          redirect_to layered_assistant.provider_models_path(@provider), notice: "Model was successfully deleted."
        else
          redirect_to layered_assistant.provider_models_path(@provider), alert: @model.errors.full_messages.to_sentence
        end
      rescue ActiveRecord::InvalidForeignKey
        redirect_to layered_assistant.provider_models_path(@provider), alert: "Cannot delete a model that is in use."
      end

      private

      def set_provider
        @provider = Provider.owned_by(l_ui_current_user).find(params[:provider_id])
      end

      def set_model
        @model = @provider.models.find(params[:id])
      end

      def model_params
        params.require(:model).permit(:name, :identifier, :enabled)
      end
    end
  end
end
