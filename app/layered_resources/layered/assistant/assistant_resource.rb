module Layered
  module Assistant
    class AssistantResource < ResourceBase
      model Layered::Assistant::Assistant

      columns [
        {
          attribute: :name,
          primary: true,
          render: ->(record, view) {
            view.link_to(record.name, view.layered_assistant.assistant_conversations_path(record))
          }
        },
        {
          attribute: :description,
          render: ->(record, view) { view.truncate(record.description.to_s, length: 60) }
        },
        {
          attribute: :default_model_id,
          label: "Default model",
          sortable: false,
          render: ->(record) { record.default_model&.name }
        },
        {
          attribute: :persona_id,
          label: "Persona",
          sortable: false,
          render: ->(record) { record.persona&.name || "None" }
        },
        {
          attribute: :assistant_skills_count,
          label: "Skills",
          render: ->(record, view) {
            view.tag.span(record.assistant_skills_count, class: "l-ui-badge--default l-ui-badge--rounded")
          }
        },
        {
          attribute: :conversations_count,
          label: "Conversations",
          render: ->(record, view) {
            view.link_to(
              view.tag.span(record.conversations_count, class: "l-ui-badge--default l-ui-badge--rounded"),
              view.layered_assistant.assistant_conversations_path(record)
            )
          }
        }
      ]

      search_fields [:name]
      default_sort attribute: :name, direction: :asc

      fields [
        { attribute: :name },
        { attribute: :description },
        { attribute: :default_model_id },
        { attribute: :instructions },
        { attribute: :persona_id },
        { attribute: :public },
        { attribute: :skill_ids, permit: [] }
      ]
    end
  end
end
