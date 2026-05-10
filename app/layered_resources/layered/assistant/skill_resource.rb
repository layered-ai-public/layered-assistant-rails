module Layered
  module Assistant
    class SkillResource < ResourceBase
      model Layered::Assistant::Skill

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
