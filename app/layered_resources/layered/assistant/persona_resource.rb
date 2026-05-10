module Layered
  module Assistant
    class PersonaResource < ResourceBase
      model Layered::Assistant::Persona

      columns [
        { attribute: :name, primary: true },
        { attribute: :description }
      ]

      search_fields [ :name ]
      default_sort attribute: :name, direction: :asc

      fields [
        { attribute: :name },
        { attribute: :description },
        { attribute: :instructions }
      ]
    end
  end
end
