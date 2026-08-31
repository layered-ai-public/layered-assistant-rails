module Layered
  module Assistant
    class PersonaResource < Layered::Resource::Base
      model Persona

      columns [
        { attribute: :name, primary: true },
        { attribute: :description, render: ->(record, view) { view.truncate(record.description, length: 60) } },
        { attribute: :assistants_count, label: "Assistants" }
      ]

      search_fields [ :name, :description ]

      default_sort attribute: :name, direction: :asc

      fields [
        { attribute: :name },
        { attribute: :description, as: :text, rows: 3 },
        { attribute: :instructions, as: :text, rows: 5,
          hint: "Shape the personality and tone of conversations, used alongside the assistant's own instructions. e.g. \"Reply in British English with a formal tone\"" }
      ]

      # Ownership stays a controller concern: both hooks defer to the
      # engine's own `scoped`/`current_owner!` helpers rather than
      # re-deriving the owner here.
      def self.scope(controller)
        controller.send(:scoped, Persona)
      end

      def self.build_record(controller)
        Persona.new(owner: controller.send(:current_owner!))
      end
    end
  end
end
