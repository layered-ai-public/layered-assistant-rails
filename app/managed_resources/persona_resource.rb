class PersonaResource < LayeredAssistantResource
  model Layered::Assistant::Persona

  columns [
    { attribute: :name, primary: true },
    { attribute: :instructions, label: "Instructions" },
    { attribute: :created_at, label: "Created" }
  ]

  fields [
    { attribute: :name },
    { attribute: :instructions, as: :text }
  ]

  search_fields [:name, :instructions]
end
