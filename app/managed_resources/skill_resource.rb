class SkillResource < Layered::ManagedResource::Base
  model Layered::Assistant::Skill

  columns [
    { attribute: :name, primary: true },
    { attribute: :description, label: "Description" },
    { attribute: :assistants_count, label: "Assistants" },
    { attribute: :created_at, label: "Created" }
  ]

  fields [
    { attribute: :name, required: true },
    { attribute: :description, as: :text },
    { attribute: :instructions, as: :text }
  ]

  search_fields [:name, :description, :instructions]

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
