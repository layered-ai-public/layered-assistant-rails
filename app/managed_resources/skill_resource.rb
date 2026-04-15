class SkillResource < LayeredAssistantResource
  model Layered::Assistant::Skill

  columns [
    { attribute: :name, primary: true },
    { attribute: :description, label: "Description" },
    { attribute: :assistants_count, label: "Assistants" },
    { attribute: :created_at, label: "Created" }
  ]

  fields [
    { attribute: :name },
    { attribute: :description, as: :text },
    { attribute: :instructions, as: :text }
  ]

  search_fields [:name, :description, :instructions]
end
