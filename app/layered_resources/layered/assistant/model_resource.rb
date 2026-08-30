module Layered
  module Assistant
    class ModelResource < Layered::Resource::Base
      model Model

      columns [
        { attribute: :name, primary: true },
        { attribute: :identifier },
        { attribute: :enabled,
          render: ->(record, view) {
            view.tag.span(record.enabled? ? "Enabled" : "Disabled",
                          class: "l-ui-badge l-ui-badge--#{record.enabled? ? 'success' : 'danger'}")
          } },
        { attribute: :assistants_count, label: "Assistants" },
        { attribute: :messages_count, label: "Messages" }
      ]

      search_fields [ :name, :identifier ]

      default_sort attribute: :position, direction: :asc

      fields [
        { attribute: :name },
        { attribute: :identifier },
        { attribute: :enabled, as: :checkbox }
      ]

      # Models are owned through their provider, so the provider is resolved
      # through the engine's own scoping and an out-of-scope one 404s before
      # any model is reached.
      def self.scope(controller)
        controller.send(:scoped, Provider).find(controller.params[:provider_id]).models
      end
    end
  end
end
