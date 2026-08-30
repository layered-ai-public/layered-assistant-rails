module Layered
  module Assistant
    class AssistantResource < Layered::Resource::Base
      model Assistant

      columns [
        { attribute: :name, primary: true },
        { attribute: :description, render: ->(record, view) { view.truncate(record.description, length: 60) } },
        { attribute: :default_model_id, label: "Default model", sortable: false,
          render: ->(record, _view) { record.default_model&.name } },
        { attribute: :persona_id, label: "Persona", sortable: false,
          render: ->(record, _view) { record.persona&.name || "None" } },
        { attribute: :assistant_skills_count, label: "Skills" },
        { attribute: :conversations_count, label: "Conversations",
          render: ->(record, view) { view.link_to(record.conversations_count, view.layered_assistant.assistant_conversations_path(record)) } }
      ]

      search_fields [ :name, :description ]

      default_sort attribute: :name, direction: :asc

      # `default_model_id`, `persona_id` and `skill_ids` carry no collection
      # here: the options have to be scoped to the owner, and only the
      # controller can resolve one. AssistantsController fills them in per
      # request.
      fields [
        { attribute: :name },
        { attribute: :description, as: :text, rows: 3 },
        { attribute: :default_model_id, label: "Default model", as: :select, include_blank: "None" },
        { attribute: :instructions, as: :text, rows: 5 },
        { attribute: :persona_id, label: "Persona", as: :select, include_blank: "None" },
        { attribute: :skill_ids, label: "Skills", as: :combobox, multiple: true, permit: [] },
        { attribute: :public, as: :checkbox }
      ]

      # Ownership stays a controller concern: both hooks defer to the
      # engine's own `scoped`/`current_owner!` helpers rather than
      # re-deriving the owner here.
      def self.scope(controller)
        controller.send(:scoped, Assistant).includes(:persona, :default_model)
      end

      def self.build_record(controller)
        Assistant.new(owner: controller.send(:current_owner!))
      end
    end
  end
end
