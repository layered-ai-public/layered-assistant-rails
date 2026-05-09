module Layered
  module Assistant
    class ModelResource < Layered::Resource::Base
      model Layered::Assistant::Model

      columns [
        { attribute: :name, primary: true },
        { attribute: :identifier },
        {
          attribute: :enabled,
          render: ->(record, view) {
            css = record.enabled? ? "l-ui-badge--success" : "l-ui-badge--danger"
            label = record.enabled? ? "Enabled" : "Disabled"
            view.tag.span(label, class: css)
          }
        },
        { attribute: :assistants_count, label: "Assistants" },
        { attribute: :messages_count, label: "Messages" }
      ]

      default_sort attribute: :position, direction: :asc

      fields [
        { attribute: :name },
        { attribute: :identifier },
        { attribute: :enabled }
      ]

      def self.scope(controller)
        parent_provider(controller).models
      end

      def self.build_record(controller)
        parent_provider(controller).models.new
      end

      def self.parent_provider(controller)
        Layered::Assistant::Provider
          .owned_by(controller.l_ui_current_user)
          .find(controller.params[:provider_id])
      end
    end
  end
end
