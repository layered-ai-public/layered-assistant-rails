module Layered
  module Assistant
    # Providers are otherwise a plain layered resource; `create` is
    # overridden only to seed the provider's models from the catalogue
    # when the new form asks for it.
    class ProvidersController < ResourcesController
      # Saving a key checks it with the provider, as the key check does.
      rate_limit to: 20, within: 1.minute, only: %i[create update]

      def create
        super.tap do
          Models::CreateService.new(@record).call if @record.persisted? && params.dig(:provider, :create_models) == "1"
        end
      end
    end
  end
end
