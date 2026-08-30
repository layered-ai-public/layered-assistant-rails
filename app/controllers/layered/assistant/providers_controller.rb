module Layered
  module Assistant
    # Providers are otherwise a plain layered resource; `create` is
    # overridden only to seed the provider's models from the catalogue
    # when the new form asks for it.
    class ProvidersController < ResourcesController
      def create
        super.tap do
          Models::CreateService.new(@record).call if @record.persisted? && params[:provider][:create_models] == "1"
        end
      end
    end
  end
end
