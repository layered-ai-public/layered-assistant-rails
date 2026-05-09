module Layered
  module Assistant
    class ProviderResource < ResourceBase
      model Layered::Assistant::Provider

      columns [
        { attribute: :name, primary: true },
        {
          attribute: :protocol,
          render: ->(record) { I18n.t("layered_assistant.protocols.#{record.protocol}") }
        },
        {
          attribute: :models_count,
          label: "Models",
          link: :provider_models,
          render: ->(record, view) {
            view.tag.span(
              record.models_count,
              class: "l-ui-badge--default l-ui-badge--rounded"
            )
          }
        },
        {
          attribute: :enabled,
          render: ->(record, view) {
            css = record.enabled? ? "l-ui-badge--success" : "l-ui-badge--danger"
            label = record.enabled? ? "Enabled" : "Disabled"
            view.tag.span(label, class: css)
          }
        }
      ]

      search_fields [ :name ]
      default_sort attribute: :position, direction: :asc

      fields [
        { attribute: :name },
        { attribute: :protocol },
        { attribute: :url },
        { attribute: :secret },
        { attribute: :enabled },
        { attribute: :create_models }
      ]
    end
  end
end
