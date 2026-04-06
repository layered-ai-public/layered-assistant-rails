module Layered
  module Assistant
    class ProvidersController < ApplicationController
      before_action :set_provider, only: [:edit, :update, :destroy]

      def index
        @page_title = "Providers"
        @pagy, @providers = pagy(scoped(Provider).sorted)
      end

      def new
        @page_title = "New Provider"
        @provider = Provider.new
      end

      def create
        @provider = Provider.new(provider_params)
        @provider.owner = l_ui_current_user

        if @provider.save
          Models::CreateService.new(@provider).call if params[:provider][:create_models] == "1"
          redirect_to layered_assistant.providers_path, notice: "Provider was successfully created."
        else
          render :new, status: :unprocessable_entity
        end
      end

      def edit
        @page_title = "Edit Provider"
      end

      def update
        if @provider.update(provider_params)
          redirect_to layered_assistant.providers_path, notice: "Provider was successfully updated."
        else
          render :edit, status: :unprocessable_entity
        end
      end

      def destroy
        @provider.destroy
        redirect_to layered_assistant.providers_path, notice: "Provider was successfully deleted."
      end

      private

      def set_provider
        @provider = scoped(Provider).find(params[:id])
      end

      def provider_params
        params.require(:provider).permit(:name, :protocol, :url, :secret, :enabled)
      end
    end
  end
end
