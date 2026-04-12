class PersonaResource < Layered::ManagedResource::Base
  model Layered::Assistant::Persona

  columns [
    { attribute: :name, primary: true },
    { attribute: :instructions, label: "Instructions" },
    { attribute: :created_at, label: "Created" }
  ]

  fields [
    { attribute: :name, required: true },
    { attribute: :instructions, required: true, as: :text }
  ]

  search_fields [:name, :instructions]

  def self.scope(controller)
    block = Layered::Assistant.scope_block
    return model.all unless block

    controller.instance_exec(model, &block)
  end

  def self.build_record(controller)
    record = scope(controller).build
    record.owner = controller.send(:current_user) if controller.respond_to?(:current_user, true)
    record
  end
end
